import re, sys

nav_items = """        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],"""

files = {
    r"lib\features\technician\screens\technician_dashboard_screen.dart": (0, False),
    r"lib\features\profile\presentation\screens\technician_profile_screen.dart": (4, False),
    r"lib\features\technician\screens\map_tracking_screen.dart": (3, True),
}

for path, (idx, remove_showfab) in files.items():
    with open(path, encoding="utf-8") as f:
        content = f.read()
    if remove_showfab:
        content = re.sub(r"\s*showFab:\s*\w+,", "", content)
    old = f"currentIndex: {idx},\n"
    new = f"currentIndex: {idx},\n{nav_items}\n"
    content = content.replace(old, new, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Fixed: {path}")
