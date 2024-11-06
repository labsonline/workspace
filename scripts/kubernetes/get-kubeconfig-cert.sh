#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e

toor

cd /etc/kubernetes/admin/pki
echo """
cert: $(cat admin.pem | base64 -w0)
"""
echo ""
echo """
key: $(cat admin-key.pem | base64 -w0)
"""
echo ""
