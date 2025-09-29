FROM manjusakalza/bpftime-base-image:ubuntu-2204
WORKDIR /bpftime

RUN apt-get update && apt-get install -y --no-install-recommends \
        lcov tree strace gdb sudo libc6-dev bpftrace \
        linux-headers-generic linux-tools-generic \
        linux-headers-$(uname -r) \
        libelf-dev procps gnupg gnupg-agent pinentry-curses dirmngr

RUN apt-get install -y gcc-10 g++-10 || true
RUN apt-get install -y gcc-11 g++-11 || true
RUN apt-get install -y gcc-12 g++-12 || true

COPY . .

RUN git submodule update --init --recursive

ENV BPFTIME_VM_NAME=llvm 
# ENV LLVM_DIR=/usr/lib/llvm-17/lib/cmake/llvm
# ENV PATH="${PATH}:/usr/lib/llvm-17/bin"
ENV SPDLOG_LEVEL=debug
ENV BPFTIME_LOG_OUTPUT=console
ENV BPFTIME_SHARED_MEMORY_PATH=/dev/shm
ENV SERVER_LOG=logs/bpftime_server.log
ENV CLIENT_LOG=logs/bpftime_client.log
ENV BPFTIME_USED=1

RUN rm -rf build && mkdir build && cmake -Bbuild \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBPFTIME_LLVM_JIT=1 \
    -DBUILD_BPFTIME_DAEMON=1 \
    -DBUILD_AGENT=1 \
    -DCMAKE_CXX_FLAGS="-DDEFAULT_LOGGER_OUTPUT_PATH='\"console\"'"
    # -DCMAKE_C_COMPILER=/usr/lib/llvm-17/bin/clang \
    # -DCMAKE_CXX_COMPILER=/usr/lib/llvm-17/bin/clang++ \
    # -DLLVM_CONFIG=/usr/lib/llvm-17/bin/llvm-config \
    # -DLLVM_DIR=/usr/lib/llvm-17/lib/cmake/llvm \
    # -DBPFTIME_ENABLE_CUDA_ATTACH=1 \
    # -DBPFTIME_CUDA_ROOT=/usr/local/cuda-12.6

# RUN cd build && make -j$(nproc)
# RUN cd build && make install
RUN cmake --build build --config RelWithDebInfo -j$(nproc)
RUN make -C example/malloc
ENV PATH="${PATH}:/root/.bpftime/"
