# CFDEMApptainer

Apptainer (Singularity) build recipe for a containerized **OpenFOAM-6 + LIGGGHTS + CFDEMcoupling + pfmFOAM** environment, set up to be built via SLURM on the MUSICA HPC cluster.

The container bundles a complete CFD-DEM stack — OpenFOAM as the CFD solver, LIGGGHTS as the DEM engine, and CFDEMcoupling as the coupling layer — plus a Python/PyTorch environment for data-assisted post-processing and modeling (`torch`, `numpy`, `pandas`, `scipy`, `matplotlib`, `geomloss`).

## Contents

| File | Purpose |
|---|---|
| `image.def` | Apptainer definition file. Bootstraps from `ubuntu:24.04`, installs system/Python dependencies, then clones and builds OpenFOAM-6, ThirdParty-6, LIGGGHTS (`develop` branch), CFDEMcoupling (`feature/recurrenceLib` branch), and pfmFOAM (`develop` branch). |
| `buildCFDEM.sh` | SLURM batch script that submits the `apptainer build` job on the MUSICA `zen4_0768` partition, binding the host's `~/.ssh` into the container so private repos (LIGGGHTS, CFDEMcoupling) can be cloned over SSH. |
| `bashrcOF` | Custom `etc/bashrc` for OpenFOAM-6, copied into the container to configure the OpenFOAM environment used during and after the build. |
| `bashrcCFDEM` | Custom `etc/bashrc` for CFDEMcoupling (version `24.01`), sourced after the OpenFOAM environment to wire up the CFDEM/LIGGGHTS paths. |
| `OSHA1stream.H` | Patched copy of OpenFOAM's `OSHA1stream.H`, dropped into `OpenFOAM-6/src/OpenFOAM/db/IOstreams/hashes/` before compilation. |

## Prerequisites

- Access to a cluster (or workstation) with **Apptainer** installed.
- An SSH key with access to the private `ParticulateFlow/LIGGGHTS` and `ParticulateFlow/CFDEMcoupling` repositories, available at `$HOME/.ssh` on the build host.
- If building via SLURM (as `buildCFDEM.sh` does): a partition/QoS matching MUSICA's `zen4_0768`, and `$DATA` / `$HOME` environment variables set as expected on that cluster.

## Building the image

1. Place `image.def`, `OSHA1stream.H`, `bashrcOF`, and `bashrcCFDEM` together under `$HOME/CFDEMApptainer` (the `%files` section of `image.def` expects them there).
2. Adjust the `%arguments` block in `image.def` if needed:
   - `user` — should match your MUSICA username.
   - `gitOpenFOAM`, `gitThirdParty`, `gitLIGGGHTS`, `gitCFDEMcoupling`, `gitpfmFoam` — source repositories/branches for each component.
3. Submit the build job:

   ```bash
   sbatch buildCFDEM.sh
   ```

   This runs:

   ```bash
   apptainer build \
       --bind "${HOME}/.ssh:/root/.ssh" \
       ${DATA}/image.sif ${HOME}/Container/image.def
   ```

   producing `image.sif` in `$DATA`. The script defaults to a full-node build (`--exclusive --contiguous` on `zen4_0768`); a commented-out partial-node block (`--ntasks=190`, `--mem=16G`) is available as an alternative.

## Running the container

The `%environment` block activates the OpenFOAM and CFDEMcoupling environments automatically on container entry, and defines a `liggghts` alias pointing at the compiled binary:

```bash
apptainer shell image.sif
# or
apptainer exec image.sif <command>
```

Inside the container, `WM_NCOMPPROCS` is exported from the build-time `nprocs`, and both `OpenFOAM-6/etc/bashrc` and `CFDEMcoupling/etc/bashrc` are sourced so `cfdemCompLIG`, `cfdemCompCFDEM`, and related CFDEM functions are available.

## Notes

- Each major compilation step (`ThirdParty-6`, `OpenFOAM-6`, LIGGGHTS, CFDEM, pfmFOAM) is wrapped with `|| echo "WARNING: ... continuing"` so a single failing component doesn't abort the whole image build — check the build log for these warnings to confirm everything actually compiled.
- `image.def` patches LIGGGHTS's `src/CMakeLists.txt` before building: Ubuntu 24.04's `libvtk9-dev` requires the `Qt5::OpenGL` imported target, which isn't otherwise resolved before `find_package(VTK ...)` runs, so a `find_package(Qt5 REQUIRED COMPONENTS OpenGL)` call is injected ahead of it via `sed`.
- Python dependencies install `torch` from the CPU-only wheel index first, so that `geomloss`'s dependency resolution finds `torch` already satisfied and doesn't pull in the much larger CUDA build from PyPI.
