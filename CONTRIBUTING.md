# Contributing to icu.breakiterator.native

Thank you for your interest in contributing!

## Development Setup

1. Clone the repository with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/yourusername/icu.breakiterator.native.git
   cd icu.breakiterator.native
   ```

2. Install platform-specific build tools (see README.md)

3. Build for your platform:
   ```bash
   # Windows
   .\build-windows.ps1

   # Linux/macOS
   ./build-linux.sh
   ```

## Making Changes

1. Create a feature branch from `main`
2. Make your changes
3. Test on all relevant platforms if possible
4. Submit a pull request

## Code Style

- Follow existing code formatting
- Add comments for complex logic
- Keep functions focused and small

## Testing

Before submitting a PR:
1. Build successfully on at least one platform
2. Verify the library loads in a .NET application
3. Test basic break iterator functionality

## Pull Request Process

1. Update README.md if adding new features
2. Update the version number in relevant files
3. Describe your changes in the PR description
4. Wait for CI/CD checks to pass
5. Request review from maintainers

## Reporting Issues

When reporting issues, please include:
- Platform and architecture
- Build error messages or runtime errors
- Steps to reproduce
- Expected vs actual behavior

Thank you for contributing!
