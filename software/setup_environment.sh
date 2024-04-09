#!/bin/bash
# Setup script for octopi-software environment
#
# Usage...
#
# brew install git (MacOS)
# sudo apt-get install git (Linux)
# 
# git clone git@github.com:sohamazing/octopi-software.git
# cd octopi-research/software
# chmod +x setup_environment.sh
# ./setup_environment.sh
#
# conda activate octopi
# python main.py --simulation

# Function definitions
version() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'
}

check_cuda_nvidia() {
    desired_cuda_version_major="12"  # Major version of desired CUDA
    desired_driver_version="550"     # Desired NVIDIA driver version

    # Extract current NVIDIA driver version
    current_driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | cut -d '.' -f1)
    echo "Current NVIDIA driver version: $current_driver_version"

    # Attempt to extract current CUDA version
    if command -v nvcc &> /dev/null; then
        current_cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d ',' -f1)
        current_cuda_version_major=$(echo $current_cuda_version | cut -d '.' -f1)
    else
        current_cuda_version_major="0"
    fi
    echo "Current CUDA major version: $current_cuda_version_major"

    # Compare versions
    if [ $(version $current_driver_version) -lt $(version $desired_driver_version) ] || 
       [ $(version $current_cuda_version_major) -ne $(version $desired_cuda_version_major) ]; then
        return 1
    else
        return 0
    fi
}

install_cuda_linux() {
    echo "System does not meet the desired requirements for CUDA or NVIDIA drivers. Installing CUDA..."
    sudo apt-get update && sudo apt-get install -y cuda
}

create_conda_env() {
    env_name="octopi"
    python_version="3.10"

    echo "Creating conda environment '$env_name' with Python $python_version if it doesn't already exist..."
    conda create -y -n $env_name python=$python_version || true
    eval "$(conda shell.bash hook)"
    conda activate $env_name
}

install_python_packages() {
    echo "Updating pip and installing Python packages..."
    pip install -U pip setuptools wheel
    pip install -U numpy pandas scikit-learn
    pip install -U PyQt5 pyqtgraph qtpy pyserial lxml==4.9.4 crc==1.3.0
    pip install -U opencv-python-headless opencv-contrib-python-headless
    pip install -U dask_image imageio aicsimageio tifffile 
    pip install -U napari[all] napari-ome-zarr basicpy
}

install_jax() {
    case "$(uname -s)" in
        Linux*)
            echo "Updating JAX with CUDA support for Linux..."
            pip install -U 'jax[cuda12_pip]==0.4.23' --find-links https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
            ;;
        Darwin*)
            echo "Updating JAX for CPU on macOS..."
            pip install -U 'jax[cpu]==0.4.23'
            ;;
        *)
            echo "Unsupported OS for specific JAX installation. Proceeding with general JAX installation."
            ;;
    esac
}

install_galaxy_camera() {
    echo "Installing Galaxy Camera software..."
    cd drivers\ and\ libraries/daheng\ camera/Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.2.1911.9122/
    ./Galaxy_camera.run
    cd ../Galaxy_Linux_Python_1.0.1905.9081/api
    python3 setup.py build
    python3 setup.py install
}

# Create and activate conda environment
create_conda_env

# Install Python packages
install_python_packages

# Conditional CUDA installation and PyTorch setup on Linux
case "$(uname -s)" in
    Linux*)
        if ! check_cuda_nvidia; then
            install_cuda_linux
            conda install -y pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
        else
            echo "CUDA and NVIDIA driver requirements are already satisfied."
        fi
        ;;
    *)
        echo "CUDA installation skipped for non-Linux systems."
        conda install -y pytorch torchvision torchaudio -c pytorch
        ;;
esac

# Install JAX
install_jax

# Install Galaxy Camera software
install_galaxy_camera

echo "Installation completed successfully."
