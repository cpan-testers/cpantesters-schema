FROM cpantesters/base
# Load some modules that will always be required, to cut down on docker
# rebuild time
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm -v --notest \
    DBIx::Class \
    DBIx::Class::Candy \
    DBD::SQLite \
    DateTime \
    DateTime::Format::ISO8601 \
    DateTime::Format::MySQL \
    DateTime::Format::SQLite \
    Mojolicious \
    Log::Any \
    Path::Tiny \
    SQL::Translator

# Load last version's modules, to again cut down on rebuild time
COPY ./cpanfile /app/cpanfile
RUN --mount=type=cache,target=/root/.cpanm \
  cpanm --installdeps --notest .

COPY ./ /app
RUN --mount=type=cache,target=/root/.cpanm \
  dzil authordeps --missing | cpanm -v --notest && \
  dzil listdeps --missing | cpanm -v --notest && \
  dzil install --install-command "cpanm -v --notest ."
