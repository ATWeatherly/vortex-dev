#!/bin/bash

# exit when any command fails
set -e

REPOSITORY=https://github.com/vortexgpgpu/vortex-toolchain-prebuilt/raw/master

DESTDIR="${DESTDIR:=/opt}"

OS="${OS:=ubuntu/bionic}"

riscv()
{
    case $OS in
    "centos/7") parts=$(eval echo {a..h}) ;;
    *)          parts=$(eval echo {a..j}) ;;
    esac
    rm -f riscv-gnu-toolchain.tar.bz2.parta*
    for x in $parts
    do
        wget $REPOSITORY/riscv-gnu-toolchain/$OS/riscv-gnu-toolchain.tar.bz2.parta$x
    done
    cat riscv-gnu-toolchain.tar.bz2.parta* > riscv-gnu-toolchain.tar.bz2
    tar -xvf riscv-gnu-toolchain.tar.bz2
    cp -r riscv-gnu-toolchain $DESTDIR
    rm -f riscv-gnu-toolchain.tar.bz2*    
    rm -rf riscv-gnu-toolchain
}

riscv64()
{
    case $OS in
    "centos/7") parts=$(eval echo {a..h}) ;;
    *)          parts=$(eval echo {a..j}) ;;
    esac
    rm -f riscv64-gnu-toolchain.tar.bz2.parta*
    for x in $parts
    do
        wget $REPOSITORY/riscv64-gnu-toolchain/$OS/riscv64-gnu-toolchain.tar.bz2.parta$x
    done
    cat riscv64-gnu-toolchain.tar.bz2.parta* > riscv64-gnu-toolchain.tar.bz2
    tar -xvf riscv64-gnu-toolchain.tar.bz2
    cp -r riscv64-gnu-toolchain $DESTDIR
    rm -f riscv64-gnu-toolchain.tar.bz2*    
    rm -rf riscv64-gnu-toolchain
}

llvm()
{
    case $OS in
    "centos/7") parts=$(eval echo {a..b}) ;;
    *)          parts=$(eval echo {a..b}) ;;
    esac
    echo $parts
    rm -f llvm-vortex.tar.bz2.parta*
    for x in $parts
    do
        wget $REPOSITORY/llvm-vortex/$OS/llvm-vortex.tar.bz2.parta$x
    done
    cat llvm-vortex.tar.bz2.parta* > llvm-vortex.tar.bz2
    tar -xvf llvm-vortex.tar.bz2
    cp -r llvm-vortex $DESTDIR
    rm -f llvm-vortex.tar.bz2*    
    rm -rf llvm-vortex
}

pocl()
{
    wget $REPOSITORY/pocl/$OS/pocl.tar.bz2
    tar -xvf pocl.tar.bz2
    rm -f pocl.tar.bz2
    cp -r pocl $DESTDIR
    rm -rf pocl
}

verilator()
{
    wget $REPOSITORY/verilator/$OS/verilator.tar.bz2
    tar -xvf verilator.tar.bz2
    cp -r verilator $DESTDIR
    rm -f verilator.tar.bz2    
    rm -rf verilator
}

show_usage()
{
    echo "Install Pre-built Vortex Toolchain"
    echo "Usage: $0 [[-riscv] [-riscv64] [-llvm] [-pocl] [-verilator] [-all] [-h|--help]]"
}

while [ "$1" != "" ]; do
    case $1 in
        -pocl ) pocl
                ;;
        -verilator ) verilator
                     ;;
        -riscv ) riscv
                 ;;
        -riscv64 ) riscv64
                 ;;
        -llvm ) llvm
                ;;
        -all ) riscv
               riscv64
               llvm
               pocl
               verilator
               ;;
        -h | --help ) show_usage
                      exit
                      ;;
        * )           show_usage
                      exit 1
    esac
    shift
done