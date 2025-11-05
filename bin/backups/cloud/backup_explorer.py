#!/usr/bin/env python3
"""
Interactive Backup Explorer for Leonardo Instances

Features:
- Browse available backups with arrow keys
- Preview backup contents
- Select which backup to use for restore
- Inspect postgres dumps and file contents
- Compare backups

Dependencies: boto3, rich
Install: pip install boto3 rich
"""

import subprocess
import sys
import tempfile
import gzip
from datetime import datetime
from pathlib import Path

try:
    import boto3
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.layout import Layout
    from rich.text import Text
    from rich.prompt import Prompt, Confirm
    from rich.tree import Tree
except ImportError:
    print("❌ Missing dependencies. Install with:")
    print("   pip install boto3 rich")
    sys.exit(1)

console = Console()


class BackupExplorer:
    def __init__(self, instance_name, s3_bucket="s3://llampress-ai-backups/backups/leonardos"):
        self.instance_name = instance_name
        # Parse S3 path: s3://bucket/prefix -> bucket and prefix
        s3_path = s3_bucket.replace("s3://", "")
        parts = s3_path.split("/", 1)
        self.s3_bucket = parts[0]  # Just the bucket name
        base_prefix = parts[1] if len(parts) > 1 else ""
        self.s3_prefix = f"{base_prefix}/{instance_name}".strip("/")
        self.s3_client = boto3.client('s3')
        self.backups = []
        self.current_selection = None

    def load_backups(self):
        """Load all available backups from S3"""
        try:
            # Get current selection
            try:
                obj = self.s3_client.get_object(
                    Bucket=self.s3_bucket,
                    Key=f"{self.s3_prefix}/latest-backup.txt"
                )
                self.current_selection = obj['Body'].read().decode('utf-8').strip()
            except:
                self.current_selection = None

            # List all backup folders
            paginator = self.s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(
                Bucket=self.s3_bucket,
                Prefix=self.s3_prefix + "/",
                Delimiter='/'
            )

            backup_folders = []
            for page in pages:
                if 'CommonPrefixes' in page:
                    for prefix in page['CommonPrefixes']:
                        folder = prefix['Prefix'].split('/')[-2]
                        if folder and folder != self.instance_name:
                            backup_folders.append(folder)

            # Get details for each backup
            self.backups = []
            for folder in sorted(backup_folders):
                files = self.list_backup_files(folder)
                if files:
                    # Get timestamp from first file
                    first_file = files[0]
                    size = sum(f['Size'] for f in files)

                    self.backups.append({
                        'timestamp': folder,
                        'date': first_file['LastModified'],
                        'files': files,
                        'size': size,
                        'is_current': folder == self.current_selection
                    })

            return True
        except Exception as e:
            console.print(f"[red]Error loading backups:[/red] {str(e)}")
            import traceback
            traceback.print_exc()
            return False

    def list_backup_files(self, timestamp):
        """List all files in a backup"""
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.s3_bucket,
                Prefix=f"{self.s3_prefix}/{timestamp}/"
            )
            return response.get('Contents', [])
        except:
            return []

    def format_size(self, size):
        """Format bytes to human readable"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} TB"

    def show_main_menu(self):
        """Display the main menu with backup list"""
        console.clear()

        # Header
        console.print(Panel(
            f"[bold cyan]Leonardo Backup Explorer[/bold cyan]\n"
            f"Instance: [yellow]{self.instance_name}[/yellow]",
            style="bold blue"
        ))
        console.print()

        if not self.backups:
            console.print("[red]No backups found![/red]")
            return

        # Create table
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("#", style="dim", width=4)
        table.add_column("Timestamp", style="cyan")
        table.add_column("Date", style="green")
        table.add_column("Files", justify="right")
        table.add_column("Size", justify="right")
        table.add_column("Status", justify="center")

        for idx, backup in enumerate(self.backups, 1):
            date_str = backup['date'].strftime('%Y-%m-%d %H:%M:%S')

            if backup['is_current']:
                status = "[bold green]✓ CURRENT[/bold green]"
            else:
                status = ""

            table.add_row(
                str(idx),
                backup['timestamp'],
                date_str,
                str(len(backup['files'])),
                self.format_size(backup['size']),
                status
            )

        console.print(table)
        console.print()

    def show_backup_details(self, backup):
        """Show detailed view of a specific backup"""
        console.clear()

        console.print(Panel(
            f"[bold cyan]Backup Details[/bold cyan]\n"
            f"Timestamp: [yellow]{backup['timestamp']}[/yellow]\n"
            f"Date: [green]{backup['date'].strftime('%Y-%m-%d %H:%M:%S')}[/green]\n"
            f"Total Size: [blue]{self.format_size(backup['size'])}[/blue]",
            style="bold blue"
        ))
        console.print()

        # Create tree of files
        tree = Tree(f"📦 {backup['timestamp']}", guide_style="bright_blue")

        # Group files by type
        file_groups = {
            'postgres': [],
            'volumes': [],
            'project': [],
            'system': [],
            'other': []
        }

        for file_obj in backup['files']:
            filename = file_obj['Key'].split('/')[-1]
            size = self.format_size(file_obj['Size'])

            if 'postgres' in filename:
                file_groups['postgres'].append((filename, size))
            elif any(v in filename for v in ['redis', 'rails_storage', 'code_config']):
                file_groups['volumes'].append((filename, size))
            elif 'project' in filename:
                file_groups['project'].append((filename, size))
            elif 'system' in filename:
                file_groups['system'].append((filename, size))
            else:
                file_groups['other'].append((filename, size))

        if file_groups['postgres']:
            branch = tree.add("🗄️  Database")
            for name, size in file_groups['postgres']:
                branch.add(f"[cyan]{name}[/cyan] [dim]({size})[/dim]")

        if file_groups['volumes']:
            branch = tree.add("📂 Docker Volumes")
            for name, size in file_groups['volumes']:
                branch.add(f"[yellow]{name}[/yellow] [dim]({size})[/dim]")

        if file_groups['project']:
            branch = tree.add("📄 Project Files")
            for name, size in file_groups['project']:
                branch.add(f"[green]{name}[/green] [dim]({size})[/dim]")

        if file_groups['system']:
            branch = tree.add("⚙️  System Config")
            for name, size in file_groups['system']:
                branch.add(f"[blue]{name}[/blue] [dim]({size})[/dim]")

        if file_groups['other']:
            branch = tree.add("📋 Other")
            for name, size in file_groups['other']:
                branch.add(f"[white]{name}[/white] [dim]({size})[/dim]")

        console.print(tree)
        console.print()

    def preview_postgres_dump(self, backup):
        """Preview contents of postgres dump"""
        # Find postgres dump file
        postgres_files = [f for f in backup['files'] if 'postgres-' in f['Key'] and f['Key'].endswith('.sql.gz')]

        if not postgres_files:
            console.print("[yellow]No postgres dump found in this backup[/yellow]")
            return

        postgres_file = postgres_files[0]

        console.print(f"[cyan]Downloading postgres dump preview...[/cyan]")

        try:
            # Download first 1MB of the gzipped file
            response = self.s3_client.get_object(
                Bucket=self.s3_bucket,
                Key=postgres_file['Key'],
                Range='bytes=0-1048576'  # First 1MB
            )

            # Decompress and read
            with tempfile.NamedTemporaryFile(suffix='.sql.gz', delete=False) as tmp:
                tmp.write(response['Body'].read())
                tmp_path = tmp.name

            with gzip.open(tmp_path, 'rt') as f:
                lines = []
                for i, line in enumerate(f):
                    if i >= 100:  # Show first 100 lines
                        break
                    lines.append(line.rstrip())

            Path(tmp_path).unlink()

            console.print(Panel(
                "\n".join(lines),
                title="[cyan]Postgres Dump Preview (first 100 lines)[/cyan]",
                border_style="cyan"
            ))

            # Try to extract some useful info
            tables = [line for line in lines if line.startswith('CREATE TABLE')]
            if tables:
                console.print(f"\n[green]Found {len(tables)} table definitions in preview[/green]")
                for table in tables[:5]:
                    console.print(f"  • {table}")

        except Exception as e:
            console.print(f"[red]Error previewing dump:[/red] {str(e)}")

    def set_current_backup(self, backup):
        """Update latest-backup.txt to point to this backup"""
        try:
            self.s3_client.put_object(
                Bucket=self.s3_bucket,
                Key=f"{self.s3_prefix}/latest-backup.txt",
                Body=backup['timestamp'].encode('utf-8')
            )
            self.current_selection = backup['timestamp']
            console.print(f"[green]✓ Set {backup['timestamp']} as current backup[/green]")
            return True
        except Exception as e:
            console.print(f"[red]Error setting backup:[/red] {str(e)}")
            return False

    def interactive_menu(self):
        """Main interactive loop"""
        while True:
            self.show_main_menu()

            console.print("[bold]Options:[/bold]")
            console.print("  [cyan]1-N[/cyan] - View backup details")
            console.print("  [cyan]s[/cyan]   - Select backup for restore")
            console.print("  [cyan]p[/cyan]   - Preview postgres dump")
            console.print("  [cyan]r[/cyan]   - Reload/refresh")
            console.print("  [cyan]q[/cyan]   - Quit")
            console.print()

            choice = Prompt.ask("Your choice").lower().strip()

            if choice == 'q':
                console.print("[yellow]Goodbye![/yellow]")
                break

            elif choice == 'r':
                console.print("[cyan]Reloading...[/cyan]")
                self.load_backups()
                continue

            elif choice == 's':
                idx_str = Prompt.ask("Enter backup number to select")
                try:
                    idx = int(idx_str) - 1
                    if 0 <= idx < len(self.backups):
                        backup = self.backups[idx]
                        if Confirm.ask(f"Set {backup['timestamp']} as current backup?"):
                            if self.set_current_backup(backup):
                                self.load_backups()  # Reload to update status
                    else:
                        console.print("[red]Invalid backup number[/red]")
                except ValueError:
                    console.print("[red]Please enter a number[/red]")

                Prompt.ask("\nPress Enter to continue")

            elif choice == 'p':
                idx_str = Prompt.ask("Enter backup number to preview")
                try:
                    idx = int(idx_str) - 1
                    if 0 <= idx < len(self.backups):
                        console.clear()
                        backup = self.backups[idx]
                        self.preview_postgres_dump(backup)
                    else:
                        console.print("[red]Invalid backup number[/red]")
                except ValueError:
                    console.print("[red]Please enter a number[/red]")

                Prompt.ask("\nPress Enter to continue")

            elif choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(self.backups):
                    backup = self.backups[idx]
                    self.show_backup_details(backup)

                    console.print("\n[bold]Actions:[/bold]")
                    console.print("  [cyan]s[/cyan] - Set as current")
                    console.print("  [cyan]p[/cyan] - Preview postgres dump")
                    console.print("  [cyan]b[/cyan] - Back to list")

                    action = Prompt.ask("Action", choices=['s', 'p', 'b'], default='b')

                    if action == 's':
                        if Confirm.ask(f"Set {backup['timestamp']} as current backup?"):
                            if self.set_current_backup(backup):
                                self.load_backups()
                    elif action == 'p':
                        console.clear()
                        self.preview_postgres_dump(backup)
                        Prompt.ask("\nPress Enter to continue")
                else:
                    console.print("[red]Invalid backup number[/red]")
                    Prompt.ask("Press Enter to continue")


def main():
    if len(sys.argv) < 2:
        console.print("[bold red]Usage:[/bold red] backup_explorer.py <instance_name> [s3_bucket]")
        console.print("\n[bold]Example:[/bold]")
        console.print("  backup_explorer.py LP-Test5")
        console.print("  backup_explorer.py LP-Test5 s3://llampress-ai-backups/backups/leonardos")
        sys.exit(1)

    instance_name = sys.argv[1]
    s3_bucket = sys.argv[2] if len(sys.argv) > 2 else "s3://llampress-ai-backups/backups/leonardos"

    explorer = BackupExplorer(instance_name, s3_bucket)

    with console.status("[cyan]Loading backups from S3...[/cyan]"):
        if not explorer.load_backups():
            sys.exit(1)

    if not explorer.backups:
        console.print(f"[red]No backups found for {instance_name}[/red]")
        sys.exit(1)

    console.print(f"[green]✓ Found {len(explorer.backups)} backups[/green]")
    console.print()

    try:
        explorer.interactive_menu()
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")


if __name__ == "__main__":
    main()
