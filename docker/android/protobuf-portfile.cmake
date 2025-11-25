# Patch für Android: Emuliertes TLS
if(VCPKG_TARGET_IS_ANDROID)
    set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -femulated-tls")
    set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -femulated-tls")
endif()