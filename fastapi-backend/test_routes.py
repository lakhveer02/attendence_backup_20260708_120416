#!/usr/bin/env python
"""Test routes registration"""
from app.main import app

print("\n=== Registered Routes ===\n")
for route in app.routes:
    if hasattr(route, 'methods') and hasattr(route, 'path'):
        print(f"{list(route.methods)[0]:6} {route.path:50} -> {route.name}")
    elif hasattr(route, 'path'):
        print(f"{'MOUNT':6} {route.path:50}")

# Check specifically for /api/v1/auth/signup
signup_routes = [r for r in app.routes if hasattr(r, 'path') and '/auth/signup' in r.path]
print(f"\n=== Signup Routes Found: {len(signup_routes)} ===\n")
for route in signup_routes:
    print(f"  Path: {route.path}")
    if hasattr(route, 'endpoint'):
        print(f"  Endpoint: {route.endpoint}")
        print(f"  Endpoint module: {route.endpoint.__module__}")
