#!/bin/bash
# usage:
# brew install git (MacOS)
# sudo apt-get install git (Linux)
# git clone git@github.com:sohamazing/octopi-software.git
# cd cd octopi-research/software
# chmod +x setup_octopi.sh
# ./setup_octopi.sh

# Create a conda environment named stitching with Python 3.10
echo "Creating conda environment 'octopi-software' with Python 3.10 if it doesnt already exist..."
env_exists=$(conda env list | grep 'octopi' || true)
    if [ -n "$env_exists" ]; then
        echo "Environment 'octopi' already exists. Checking Python version..."
        python_version=$(python --version)
        if [[ "$python_version" == *"Python 3.10"* ]]; then
            echo "Python 3.10 is already installed in 'octopi'. Proceeding with activation."
        else
            echo "Environment 'octopi' does not have Python 3.10. Recreating environment with Python 3.10..."
            conda create -y -n octopi python=3.10 --force
        fi
    else
        echo "Creating conda environment 'octopi' with Python 3.10..."
        conda create -y -n octopi python=3.10
    fi

# Activate the stitching environment
# echo "Activating the 'octopi-software' environment..."
eval "$(conda shell.bash hook)"
conda activate octopi

# Update pip in the activated environment to ensure we're using the latest version
echo "Updating pip..."
pip install -U pip setuptools wheel

# Install jax and jaxlib first (general installation)
#echo "Installing general jax and jaxlib dependencies..."
#conda install -U jax jaxlib

# Install other requirements before updating JAX to the specific version needed
echo "Installing other requirements..."
pip install -U numpy pandas scikit-learn

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
    pip install -U cuda-python cupy-cuda12x
    #pip install nvidia-cublas-cu12==12.1
    conda install -y pytorch torchvision torchaudio cudatoolkit -c pytorch
}


# Define a function to update JAX for CPU on macOS with the specific version
install_mac() {
    echo "Updating JAX for CPU on macOS..."
    conda install pytorch torchvision torchaudio -c pytorch -y
}

# Conditional update of JAX based on the operating system
case "$(uname -s)" in
    Linux*)     install_cuda_linux;;
    Darwin*)    install_mac;;
    *)          echo "Unsupported OS for specific JAX installation. Proceeding with general JAX installation.";;
esac

pip install -U PyQt5 pyqtgraph qtpy pyserial
pip install lxml==4.9.4 crc==1.3.0
pip install -U opencv-python-headless opencv-contrib-python-headless
pip install -U dask_image imageio aicsimageio tifffile 
pip install -U napari[all] napari-ome-zarr basicpy

# Define a function to update JAX with CUDA support on Linux
update_jax_cuda_linux() {
    echo "Updating JAX with CUDA support for Linux..."
    pip install -U 'jax[cuda12_pip]==0.4.23' --find-links https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
}

# Define a function to update JAX for CPU on macOS with the specific version
update_jax_cpu_mac() {
    echo "Updating JAX for CPU on macOS..."
    pip install -U 'jax[cpu]==0.4.23'
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
python3 setup.py build
python3 setup.py install

echo "Installation completed successfully."
