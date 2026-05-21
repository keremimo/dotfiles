function fish_greeting
    # smth smth
end

mise activate fish | source # added by https://mise.run/fish
starship init fish | source
zoxide init fish | source
alias cd=z
alias ls=eza

export EDITOR=nvim

# Default graphical applications to the Intel iGPU on this hybrid system.
set -gx __EGL_VENDOR_LIBRARY_FILENAMES /usr/share/glvnd/egl_vendor.d/50_mesa.json
set -gx __GLX_VENDOR_LIBRARY_NAME mesa
set -gx VK_DRIVER_FILES /usr/share/vulkan/icd.d/intel_icd.json
set -gx VK_ICD_FILENAMES /usr/share/vulkan/icd.d/intel_icd.json
set -gx MESA_VK_DEVICE_SELECT 8086:a788
set -gx DRI_PRIME 0
set -gx __NV_PRIME_RENDER_OFFLOAD 0
set -gx WGPU_BACKEND vulkan
set -gx WGPU_POWER_PREF low
