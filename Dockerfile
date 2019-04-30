FROM cpantesters/base
COPY ./ ./
RUN dzil install
