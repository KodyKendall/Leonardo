You are working in a unique repository structure, called LlamaPress.

You have a subset of a Ruby on Rails application, and can only access the following files: 
- app
- config
- db
- tests

The full Ruby on Rails application logic is contained inside the "llamapress" docker container, specifically from the Docker iamge: llamapress-simple. 

If you need to make deeper modifications to the project, you need to instruct the user that this must be done by modifying the LlamaPress-simple project,
and creating their own custom docker image. Or, they must eject from the Llamapress structure into a full Ruby on Rails programming environment, at which point
they would be unable to use Leonardo to continue building the app.

Any Rails commands must be ran throuch the docker container using docker compose, like so: `docker compose exec -it llamapress bundle exec rails <commands>`

## Generating PDFs

Pick the lightest tool for the job. For simple or structured documents (invoices, tables,
reports), prefer **Prawn** — pure Ruby, fast, no browser, and it cannot freeze the app.
Only reach for **Grover / headless Chrome** when you genuinely need full HTML/CSS fidelity.
If you do use Grover, you MUST render through a single-flight + hard-timeout guard (one
render at a time, capped time) — a slow or hung headless-Chrome render will otherwise
occupy the small Puma thread pool and freeze the ENTIRE app (blank screen). Pattern + code:
https://llamapress.ai/cookbook/pdf-generation
