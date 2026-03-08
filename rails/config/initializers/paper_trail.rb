# frozen_string_literal: true

# PaperTrail configuration for model versioning/audit trail
# https://github.com/paper-trail-gem/paper_trail

PaperTrail.config.enabled = true

# Track who made changes (requires setting PaperTrail.request.whodunnit in ApplicationController)
PaperTrail.config.track_associations = false  # Set to true if you need association tracking

# Optional: Customize version class name
# PaperTrail.config.version_class_name = "Version"

# Optional: Serialize object changes as JSON instead of YAML (recommended for new projects)
# PaperTrail.config.serializer = PaperTrail::Serializers::JSON
