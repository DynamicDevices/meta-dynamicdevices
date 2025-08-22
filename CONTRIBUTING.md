# Contributing to meta-dynamicdevices

We welcome contributions to the meta-dynamicdevices layer! This document outlines the process for contributing and the standards we expect for submissions.

## Getting Started

1. **Fork the Repository**: Create a fork of the meta-dynamicdevices repository on GitHub
2. **Clone Your Fork**: Clone your fork locally and set up the development environment
3. **Create a Branch**: Create a feature branch for your changes from the main branch

```bash
git clone https://github.com/yourusername/meta-dynamicdevices.git
cd meta-dynamicdevices
git checkout -b feature/your-feature-name
```

## Development Guidelines

### Code Style and Standards

- **Follow Yocto Project Standards**: All recipes and configuration files should follow [Yocto Project development standards](https://docs.yoctoproject.org/dev-manual/dev-manual-common-tasks.html)
- **Recipe Naming**: Use standard Yocto naming conventions (`packagename_version.bb`)
- **License Compliance**: All recipes must include proper `LICENSE` and `LIC_FILES_CHKSUM` declarations
- **Variable Naming**: Use consistent variable naming following Yocto conventions

### Recipe Requirements

1. **Metadata**: Include proper `SUMMARY`, `DESCRIPTION`, `LICENSE`, and `HOMEPAGE` fields
2. **Dependencies**: Clearly specify `DEPENDS` and `RDEPENDS` 
3. **Machine Compatibility**: Use appropriate `COMPATIBLE_MACHINE` restrictions
4. **Testing**: Test recipes on relevant hardware platforms
5. **Documentation**: Comment complex configurations and customizations

### Machine Configuration

- **Inheritance**: Use proper machine inheritance chains (e.g., inherit from upstream EVK configs)
- **Feature Flags**: Use `MACHINE_FEATURES` appropriately for hardware capabilities
- **Kernel Configuration**: Keep kernel customizations minimal and well-documented
- **Device Trees**: Maintain clean device tree customizations with clear purposes

## Submission Process

### Before Submitting

1. **Test Your Changes**: Ensure builds complete successfully on target hardware
2. **Check Compliance**: Verify your changes follow Yocto layer standards
3. **Update Documentation**: Update README.md if adding new machines or features
4. **Sign Your Work**: All commits must include a Signed-off-by line

### Pull Request Guidelines

1. **Clear Title**: Use descriptive titles that explain the change
2. **Detailed Description**: Explain what changes were made and why
3. **Testing Information**: Include details about testing performed
4. **Breaking Changes**: Clearly document any breaking changes
5. **Related Issues**: Reference any related GitHub issues

### Commit Message Format

Follow the conventional commit format:

```
type(scope): brief description

Detailed explanation of the changes made, why they were
necessary, and any relevant background information.

Signed-off-by: Your Name <your.email@example.com>
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Examples**:
- `feat(machine): add support for imx93-jaguar-eink board`
- `fix(u-boot): correct SPI configuration for imx93 boards`
- `docs(readme): update build instructions for mfgtool support`

## Testing Requirements

### Build Testing

- **Clean Builds**: Ensure recipes build cleanly from scratch
- **Multiple Configurations**: Test with different `MACHINE` and `DISTRO` settings
- **Dependencies**: Verify all dependencies are properly declared

### Hardware Testing

- **Boot Testing**: Verify images boot successfully on target hardware
- **Feature Validation**: Test that hardware features work as expected
- **Regression Testing**: Ensure changes don't break existing functionality

### Layer Compliance

Run layer compliance checks where possible:
```bash
yocto-check-layer /path/to/meta-dynamicdevices
```

## Review Process

1. **Automated Checks**: Pull requests trigger automated build and compliance checks
2. **Maintainer Review**: Core maintainers review all submissions
3. **Testing Phase**: Changes may undergo additional testing on target hardware
4. **Integration**: Approved changes are merged into the main branch

## Reporting Issues

When reporting bugs or requesting features:

1. **Search Existing Issues**: Check if the issue already exists
2. **Use Issue Templates**: Fill out the provided issue template completely
3. **Provide Context**: Include build logs, hardware details, and reproduction steps
4. **Be Specific**: Clear, detailed reports help us address issues faster

## Communication

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: Contact maintainers directly for sensitive issues

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- **Be Respectful**: Treat all community members with respect
- **Be Constructive**: Provide helpful feedback and suggestions
- **Be Patient**: Understand that reviews and responses take time
- **Follow Guidelines**: Adhere to these contribution guidelines

## License

By contributing to meta-dynamicdevices, you agree that your contributions will be licensed under the same terms as the project (MIT License for the layer, individual recipe licenses as specified).

## Getting Help

If you need help with contributing:

- **Documentation**: Check the Yocto Project documentation
- **Issues**: Create a GitHub issue with the "question" label
- **Maintainers**: Contact the maintainers listed in the MAINTAINERS file

Thank you for contributing to meta-dynamicdevices! Your contributions help make this layer better for the entire community.