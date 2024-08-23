# Add nano to the Foundries image
FROM hub.foundries.io/lmp-sdk:93

RUN apt update && apt install -y nano

