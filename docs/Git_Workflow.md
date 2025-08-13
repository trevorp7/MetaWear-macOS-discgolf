# Git Workflow for MetaWear macOS App

## Quick Push to Main

This project uses a simple workflow - all changes are pushed directly to the main branch.

### Daily Workflow

1. **Make your changes** to the code
2. **Stage all changes:**
   ```bash
   git add .
   ```
3. **Commit with a descriptive message:**
   ```bash
   git commit -m "Description of your changes"
   ```
4. **Push to main:**
   ```bash
   git push origin main
   ```

### Example Workflow

```bash
# After making changes to your code
git add .
git commit -m "Added motion detection feature"
git push origin main
```

### Useful Commands

- **Check status:** `git status`
- **See recent commits:** `git log --oneline -10`
- **Pull latest changes:** `git pull origin main`
- **See what files changed:** `git diff`

### Repository Info

- **Remote URL:** https://github.com/trevorp7/MetaWear-macOS-discgolf.git
- **Main branch:** main
- **No staging/dev branches** - everything goes directly to main

### Notes

- The `MetaWear-Swift-Combine-SDK/` folder is excluded from git (it's a separate repository)
- `.DS_Store` and other macOS/Xcode files are automatically ignored
- Always use descriptive commit messages
- **Only push to git when explicitly requested** - don't push automatically
