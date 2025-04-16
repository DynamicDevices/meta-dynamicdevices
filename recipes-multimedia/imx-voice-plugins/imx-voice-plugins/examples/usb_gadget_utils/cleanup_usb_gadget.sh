#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 NXP

GADGET=/sys/kernel/config/usb_gadget/g1

rm -f $GADGET/configs/c.1/uac2.*

rm -rf $GADGET/configs/c.1/strings/0x409
rm -rf $GADGET/configs/c.1

rm -rf $GADGET/functions/*

rm -rf $GADGET/strings/0x409
rm -rf $GADGET
