# /// script
# dependencies = ["requests"]
# ///

import json, os, pathlib, shutil, subprocess, sys, zipfile, requests

ROOT = pathlib.Path(__file__).parent.resolve()
DIST = ROOT / "dist"

if (env_file := ROOT / ".env").exists():
    for line in env_file.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip("'\""))

MODS_DIR = pathlib.Path(
    os.getenv("FACTORIO_MODS_DIR")
    or (
        "~/Library/Application Support/factorio/mods" if sys.platform == "darwin"
        else os.path.expandvars("%APPDATA%/Factorio/mods") if sys.platform == "win32"
        else "~/.factorio/mods"
    )
).expanduser()


def git(*args) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True).stdout.strip()


def get_info() -> dict:
    try:
        info = json.loads((ROOT / "info.json").read_text())
        req = ["name", "version", "title", "author", "factorio_version", "dependencies"]
        if missing := [k for k in req if k not in info]:
            sys.exit(f"Error: info.json missing required fields: {missing}")
        return info
    except Exception as e:
        sys.exit(f"Error reading info.json: {e}")


def check_env(require_clean: bool = False) -> tuple[dict, str]:
    info = get_info()
    ver = info["version"]
    if not (ROOT / "changelog.txt").exists() or f"Version: {ver}" not in (ROOT / "changelog.txt").read_text():
        sys.exit(f"Error: changelog.txt missing or lacks entry for 'Version: {ver}'.")
    if (changes := git("status", "--porcelain")) and require_clean:
        sys.exit(f"Error: Git working tree has uncommitted changes:\n{changes}")
    return info, ver


def get_files() -> list[pathlib.Path]:
    ignored = {".git", ".github", ".env", "dist", "mise.toml", "selene.toml", "build.py"}
    tracked = [ROOT / f for f in git("ls-files").splitlines() if f]
    return [
        p for p in (tracked or ROOT.rglob("*"))
        if p.is_file() and not any(
            part in ignored or part.startswith(("README", "LICENSE")) or part.endswith((".zip", ".webp"))
            for part in p.relative_to(ROOT).parts
        )
    ]


def check_cmd():
    info, ver = check_env()
    clean = not git("status", "--porcelain")
    tags = [t for t in git("tag", "--points-at", "HEAD").splitlines() if t]
    tagged = f"v{ver}" in tags or ver in tags
    tag_str = ", ".join(tags) if tags else "none"
    print(f"Pre-flight validation checks passed:\n  [OK] info.json (name: '{info['name']}', version: '{ver}')\n"
          f"  [OK] changelog.txt (contains entry for Version: {ver})\n"
          f"  [INFO] Git status: {'clean' if clean else 'dirty (uncommitted changes)'}\n"
          f"  [INFO] Tag status: {'tagged (' + tag_str + ')' if tagged else f'NOT tagged on HEAD (tags: {tag_str})'}")


def build_cmd() -> pathlib.Path:
    info = get_info()
    mod_id = f"{info['name']}_{info['version']}"
    DIST.mkdir(exist_ok=True)
    zip_path = DIST / f"{mod_id}.zip"
    files = get_files()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for p in files:
            zf.write(p, f"{mod_id}/{p.relative_to(ROOT)}")
    print(f"Built {zip_path.relative_to(ROOT)} ({len(files)} files)")
    return zip_path


def release_cmd():
    _, ver = check_env(require_clean=True)
    tag = f"v{ver}"
    tags = git("tag", "--points-at", "HEAD").splitlines()
    if tag in tags or ver in tags:
        print(f"Git tag '{tag}' already points at current HEAD.")
        return
    print(f"Creating annotated git tag '{tag}'...")
    subprocess.run(["git", "tag", "-a", tag, "-m", f"Release {tag}"], cwd=ROOT, check=True)
    print(f"Pushing tag '{tag}' to origin...")
    if subprocess.run(["git", "push", "origin", tag], cwd=ROOT).returncode == 0:
        print(f"Tag '{tag}' successfully created and pushed to origin.")
    else:
        print(f"Warning: Tag '{tag}' created locally, but pushing to origin failed.")


def upload_cmd():
    dry_run = "--dry-run" in sys.argv
    allow_untagged = (
        any(a in sys.argv for a in ("--allow-untagged", "--skip-tag-check"))
        or os.getenv("ALLOW_UNTAGGED", "").lower() in ("1", "true", "yes")
    )
    info, ver = check_env(require_clean=True)
    name = info["name"]
    tags = git("tag", "--points-at", "HEAD").splitlines()
    if f"v{ver}" not in tags and ver not in tags:
        if allow_untagged:
            print("[INFO] Bypassing tag check for upload (allow_untagged is set).")
        else:
            sys.exit(f"Error: Upload blocked. Current HEAD is not tagged with '{ver}'. Found tags: {tags}.")

    api_key = os.getenv("FACTORIO_API_KEY") or sys.exit("Error: FACTORIO_API_KEY environment variable required for upload.")
    zip_path = DIST / f"{name}_{ver}.zip"
    if not zip_path.exists():
        zip_path = build_cmd()

    if dry_run:
        print(f"[DRY RUN] Would upload {zip_path.name} to Factorio Mod Portal for mod '{name}'.")
        return

    print(f"Uploading {zip_path.name} to Factorio Mod Portal...")
    headers = {"Authorization": f"Bearer {api_key}"}
    try:
        init_resp = requests.post("https://mods.factorio.com/api/v2/mods/releases/init_upload", headers=headers, data={"mod": name})
        init_resp.raise_for_status()
        init = init_resp.json()
        if "upload_url" not in init:
            sys.exit(f"Error: Init upload failed: {init}")
        with open(zip_path, "rb") as f:
            upload_resp = requests.post(init["upload_url"], headers=headers, files={"file": f})
            upload_resp.raise_for_status()
            print("Upload completed successfully:\n", json.dumps(upload_resp.json(), indent=2))
    except Exception as e:
        sys.exit(f"Error: File upload failed: {e}")


def remove_path(path: pathlib.Path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def link_cmd():
    target = MODS_DIR / get_info()["name"]
    MODS_DIR.mkdir(parents=True, exist_ok=True)
    remove_path(target)
    if sys.platform == "win32":
        subprocess.run(["cmd", "/c", "mklink", "/J", str(target), str(ROOT)], check=True)
    else:
        target.symlink_to(ROOT, target_is_directory=True)
    print(f"Symlinked: {target} -> {ROOT}")


def unlink_cmd():
    target = MODS_DIR / get_info()["name"]
    if target.is_symlink() or target.exists():
        remove_path(target)
        print(f"Removed symlink: {target}")
    else:
        print(f"No symlink found at {target}")


if __name__ == "__main__":
    commands = {
        "check": check_cmd,
        "build": build_cmd,
        "upload": upload_cmd,
        "release": release_cmd,
        "link": link_cmd,
        "unlink": unlink_cmd,
    }
    cmd = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else "build"
    if cmd in commands:
        commands[cmd]()
    else:
        sys.exit(f"Unknown command '{cmd}'. Available commands: {list(commands.keys())}")
