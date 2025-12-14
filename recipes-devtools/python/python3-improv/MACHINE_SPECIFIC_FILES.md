# Machine-Specific Files Pattern for Yocto Recipes

## Standard Pattern

When creating machine-specific files in Yocto recipes, use **machine-named subdirectories directly** in the recipe directory, **NOT** a `files/` wrapper directory.

## Directory Structure

```
recipes-devtools/python/python3-improv/
├── common-file.service              (common - all machines)
├── common-script.py                 (common - all machines)
├── recipe_name.bb                   (recipe file)
└── imx93-jaguar-eink/              (machine-specific folder)
    ├── machine-specific.service
    └── machine-specific-script.py
```

## Recipe Configuration

### 1. Extend File Search Path

```bitbake
# Extend file search path to include machine-specific directories
# Yocto will automatically look in ${MACHINE}/ before recipe directory
FILESEXTRAPATHS_prepend := "${THISDIR}:"
```

### 2. Conditionally Include Machine-Specific Files in SRC_URI

```bitbake
SRC_URI = "git://github.com/example/repo.git;branch=main \
           file://common-file.service \
           file://common-script.py \
           ${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', 'file://machine-specific.service file://machine-specific-script.py', '', d)} \
"
```

### 3. Install Machine-Specific Files Conditionally

```bitbake
do_install() {
  # Install common files
  install -m 0644 ${WORKDIR}/common-file.service ${D}/${systemd_unitdir}/system
  
  # Install machine-specific files if they exist
  # Yocto automatically picks up ${MACHINE}/* files
  if [ -f ${WORKDIR}/machine-specific.service ]; then
    install -m 0644 ${WORKDIR}/machine-specific.service ${D}/${systemd_unitdir}/system
  fi
  if [ -f ${WORKDIR}/machine-specific-script.py ]; then
    install -m 0755 ${WORKDIR}/machine-specific-script.py ${D}${datadir}/app
  fi
}
```

### 4. Conditionally Select Machine-Specific Service

```bitbake
# Use machine-specific service if it exists, otherwise use default
# Yocto automatically picks up files from ${MACHINE}/ subdirectory
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', 'machine-specific.service', 'common-file.service', d)}"
```

## How It Works

1. **FILESEXTRAPATHS**: Extends the file search path to the recipe directory (`THISDIR`)
2. **Automatic Lookup**: Yocto automatically looks in `${MACHINE}/` subdirectory first
3. **Machine-Specific**: For `imx93-jaguar-eink`, files are found in `imx93-jaguar-eink/`
4. **Other Machines**: For other machines, files are found in the recipe directory root

## Example: python3-improv Recipe

**Structure:**
```
recipes-devtools/python/python3-improv/
├── improv.service                    (common - all machines)
├── onboarding-server.py              (common - all machines)
├── python3-improv_git.bb            (recipe)
└── imx93-jaguar-eink/               (machine-specific folder)
    ├── improv-eink.service
    └── onboarding-server-eink.py
```

**Result:**
- `imx93-jaguar-eink`: Uses files from `imx93-jaguar-eink/` subdirectory
- All other machines (sentai, etc.): Use files from recipe directory root
- No changes to original files - other machine behavior preserved

## Key Points

✅ **DO**: Use machine-named subdirectories directly (e.g., `imx93-jaguar-eink/`)
❌ **DON'T**: Use a `files/` wrapper directory (e.g., `files/imx93-jaguar-eink/`)

✅ **DO**: Use `FILESEXTRAPATHS_prepend := "${THISDIR}:"`
❌ **DON'T**: Use `FILESEXTRAPATHS_prepend := "${THISDIR}/files:"`

This is the **standard Yocto pattern** - cleaner, simpler, and more maintainable.

