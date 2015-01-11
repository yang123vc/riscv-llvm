; RUN: llc -march=amdgcn -mcpu=SI -verify-machineinstrs < %s | FileCheck -check-prefix=SI -check-prefix=FUNC %s
; RUN: llc -march=r600 -mcpu=redwood < %s | FileCheck -check-prefix=R600 -check-prefix=FUNC %s

; FUNC-LABEL: {{^}}fneg_fabs_fadd_f32:
; SI-NOT: and
; SI: v_sub_f32_e64 {{v[0-9]+}}, {{s[0-9]+}}, |{{v[0-9]+}}|
define void @fneg_fabs_fadd_f32(float addrspace(1)* %out, float %x, float %y) {
  %fabs = call float @llvm.fabs.f32(float %x)
  %fsub = fsub float -0.000000e+00, %fabs
  %fadd = fadd float %y, %fsub
  store float %fadd, float addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}fneg_fabs_fmul_f32:
; SI-NOT: and
; SI: v_mul_f32_e64 {{v[0-9]+}}, {{s[0-9]+}}, -|{{v[0-9]+}}|
; SI-NOT: and
define void @fneg_fabs_fmul_f32(float addrspace(1)* %out, float %x, float %y) {
  %fabs = call float @llvm.fabs.f32(float %x)
  %fsub = fsub float -0.000000e+00, %fabs
  %fmul = fmul float %y, %fsub
  store float %fmul, float addrspace(1)* %out, align 4
  ret void
}

; DAGCombiner will transform:
; (fabs (f32 bitcast (i32 a))) => (f32 bitcast (and (i32 a), 0x7FFFFFFF))
; unless isFabsFree returns true

; FUNC-LABEL: {{^}}fneg_fabs_free_f32:
; R600-NOT: AND
; R600: |PV.{{[XYZW]}}|
; R600: -PV

; SI: v_mov_b32_e32 [[IMMREG:v[0-9]+]], 0x80000000
; SI: v_or_b32_e32 v{{[0-9]+}}, s{{[0-9]+}}, [[IMMREG]]
define void @fneg_fabs_free_f32(float addrspace(1)* %out, i32 %in) {
  %bc = bitcast i32 %in to float
  %fabs = call float @llvm.fabs.f32(float %bc)
  %fsub = fsub float -0.000000e+00, %fabs
  store float %fsub, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}fneg_fabs_fn_free_f32:
; R600-NOT: AND
; R600: |PV.{{[XYZW]}}|
; R600: -PV

; SI: v_mov_b32_e32 [[IMMREG:v[0-9]+]], 0x80000000
; SI: v_or_b32_e32 v{{[0-9]+}}, s{{[0-9]+}}, [[IMMREG]]
define void @fneg_fabs_fn_free_f32(float addrspace(1)* %out, i32 %in) {
  %bc = bitcast i32 %in to float
  %fabs = call float @fabs(float %bc)
  %fsub = fsub float -0.000000e+00, %fabs
  store float %fsub, float addrspace(1)* %out
  ret void
}

; FUNC-LABEL: {{^}}fneg_fabs_f32:
; SI: v_mov_b32_e32 [[IMMREG:v[0-9]+]], 0x80000000
; SI: v_or_b32_e32 v{{[0-9]+}}, s{{[0-9]+}}, [[IMMREG]]
define void @fneg_fabs_f32(float addrspace(1)* %out, float %in) {
  %fabs = call float @llvm.fabs.f32(float %in)
  %fsub = fsub float -0.000000e+00, %fabs
  store float %fsub, float addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}v_fneg_fabs_f32:
; SI: v_or_b32_e32 v{{[0-9]+}}, 0x80000000, v{{[0-9]+}}
define void @v_fneg_fabs_f32(float addrspace(1)* %out, float addrspace(1)* %in) {
  %val = load float addrspace(1)* %in, align 4
  %fabs = call float @llvm.fabs.f32(float %val)
  %fsub = fsub float -0.000000e+00, %fabs
  store float %fsub, float addrspace(1)* %out, align 4
  ret void
}

; FUNC-LABEL: {{^}}fneg_fabs_v2f32:
; R600: |{{(PV|T[0-9])\.[XYZW]}}|
; R600: -PV
; R600: |{{(PV|T[0-9])\.[XYZW]}}|
; R600: -PV

; FIXME: SGPR should be used directly for first src operand.
; SI: v_mov_b32_e32 [[IMMREG:v[0-9]+]], 0x80000000
; SI-NOT: 0x80000000
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
define void @fneg_fabs_v2f32(<2 x float> addrspace(1)* %out, <2 x float> %in) {
  %fabs = call <2 x float> @llvm.fabs.v2f32(<2 x float> %in)
  %fsub = fsub <2 x float> <float -0.000000e+00, float -0.000000e+00>, %fabs
  store <2 x float> %fsub, <2 x float> addrspace(1)* %out
  ret void
}

; FIXME: SGPR should be used directly for first src operand.
; FUNC-LABEL: {{^}}fneg_fabs_v4f32:
; SI: v_mov_b32_e32 [[IMMREG:v[0-9]+]], 0x80000000
; SI-NOT: 0x80000000
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
; SI: v_or_b32_e32 v{{[0-9]+}}, v{{[0-9]+}}, [[IMMREG]]
define void @fneg_fabs_v4f32(<4 x float> addrspace(1)* %out, <4 x float> %in) {
  %fabs = call <4 x float> @llvm.fabs.v4f32(<4 x float> %in)
  %fsub = fsub <4 x float> <float -0.000000e+00, float -0.000000e+00, float -0.000000e+00, float -0.000000e+00>, %fabs
  store <4 x float> %fsub, <4 x float> addrspace(1)* %out
  ret void
}

declare float @fabs(float) readnone
declare float @llvm.fabs.f32(float) readnone
declare <2 x float> @llvm.fabs.v2f32(<2 x float>) readnone
declare <4 x float> @llvm.fabs.v4f32(<4 x float>) readnone
