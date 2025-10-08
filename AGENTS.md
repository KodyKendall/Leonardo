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

