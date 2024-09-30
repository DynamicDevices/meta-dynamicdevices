#!/bin/sh

echo Running CE radar testing...

while [ TRUE ]
do
  seamless_dev_spi spi.mode=landscape rec.file=/dev/null
done

