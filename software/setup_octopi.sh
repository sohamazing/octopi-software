#!/bin/bash
# usage:
# brew install git (MacOS)
# sudo apt-get install git (Linux)
# git clone git@github.com:sohamazing/octopi-software.git
# cd cd octopi-research/software
# chmod +x setup_octopi.sh
# ./setup_octopi.sh

# Create a conda environment named stitching with Python 3.10
echo "Creating conda environment 'octopi-software' with Python 3.10..."
conda create -y -n octopi python=3.10

# Activate the stitching environment
# echo "Activating the 'octopi-software' environment..."
conda activate octopi 
source activate octopi

# Update pip in the activated environment to ensure we're using the latest version
echo "Updating pip..."
conda run -n octopi pip install -U pip setuptools wheel

# Install jax and jaxlib first (general installation)
echo "Installing general jax and jaxlib dependencies..."
conda run -n octopi pip install -U jax jaxlib

# Install other requirements before updating JAX to the specific version needed
echo "Installing other requirements..."
conda run -n octopi pip install -U numpy pandas scikit-learn

install_cuda_linux() {
    echo "Updating apt and apt-get..."
    sudo apt-get update && sudo apt update

    echo "Installing nvidia-driver-535..."
    #sudo apt install nvidia-driver-535 || exit

    cwd=$(pwd)
    cd ~/Downloads || exit
    echo "Downloading and installing CUDA keyring..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb || exit
    sudo dpkg -i cuda-keyring_1.1-1_all.deb || exit
    rm cuda-keyring_1.1-1_all.deb  # Clean up the downloaded file
    cd "$cwd" || exit

    echo "Installing CUDA..."
    sudo apt-get install cuda

    echo "Installing Python packages for CUDA support..."
    conda run -n octopi pip install -U cuda-python cupy-cuda12x
    #conda run -n octopi pip install nvidia-cublas-cu12==12.1
    conda run -n octopi conda install -y pytorch torchvision torchaudio cudatoolkit -c pytorch
}


# Define a function to update JAX for CPU on macOS with the specific version
install_mac() {
    echo "Updating JAX for CPU on macOS..."
    conda run -n octopi pip install -U torch torchvision torch audio
}

# Conditional update of JAX based on the operating system
case "$(uname -s)" in
    Linux*)     install_cuda_linux;;
    Darwin*)    install_mac;;
    *)          echo "Unsupported OS for specific JAX installation. Proceeding with general JAX installation.";;
esac

conda run -n octopi pip install -U PyQt5 pyqtgraph qtpy pyserial
conda run -n octopi pip install lxml==4.9.4 crc==1.3.0
conda run -n octopi pip install -U opencv-python-headless opencv-contrib-python-headless
conda run -n octopi pip install -U dask_image imageio aicsimageio tifffile 
conda run -n octopi pip install -U napari[all] napari-ome-zarr basicpy

# Define a function to update JAX with CUDA support on Linux
update_jax_cuda_linux() {
    echo "Updating JAX with CUDA support for Linux..."
    conda run -n octopi pip install -U 'jax[cuda12_pip]==0.4.23' --find-links https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
}

# Define a function to update JAX for CPU on macOS with the specific version
update_jax_cpu_mac() {
    echo "Updating JAX for CPU on macOS..."
    conda run -n octopi pip install -U 'jax[cpu]==0.4.23'
}

# Conditional update of JAX based on the operating system
case "$(uname -s)" in
    Linux*)     update_jax_cuda_linux;;
    Darwin*)    update_jax_cpu_mac;;
    *)          echo "Unsupported OS for specific JAX installation. Proceeding with general JAX installation.";;
esac

mkdir cache
cd drivers\ and\ libraries/daheng\ camera/Galaxy_Linux-x86_Gige-U3_32bits-64bits_1.2.1911.9122/
./Galaxy_camera.run

cd ../Galaxy_Linux_Python_1.0.1905.9081/api
conda run -n octopi python3 setup.py build
conda run -n octopi python3 setup.py install

echo "Installation completed successfully."
