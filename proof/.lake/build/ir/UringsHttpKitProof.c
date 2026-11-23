// Lean compiler output
// Module: UringsHttpKitProof
// Imports: public import Init public meta import Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
lean_object* lean_nat_sub(lean_object*, lean_object*);
lean_object* lean_nat_mul(lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
lean_object* lean_nat_mod(lean_object*, lean_object*);
uint8_t lean_nat_dec_lt(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decode(lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof___private_UringsHttpKitProof_0__UringsHttpKitProof_Varint_decodeSpec_match__1_splitter___redArg(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof___private_UringsHttpKitProof_0__UringsHttpKitProof_Varint_decodeSpec_match__1_splitter(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7(lean_object* v_acc_1_, lean_object* v_b_2_){
_start:
{
lean_object* v___x_3_; lean_object* v___x_4_; lean_object* v___x_5_; lean_object* v___x_6_; 
v___x_3_ = lean_unsigned_to_nat(128u);
v___x_4_ = lean_nat_mul(v_acc_1_, v___x_3_);
v___x_5_ = lean_nat_mod(v_b_2_, v___x_3_);
v___x_6_ = lean_nat_add(v___x_4_, v___x_5_);
lean_dec(v___x_5_);
lean_dec(v___x_4_);
return v___x_6_;
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7___boxed(lean_object* v_acc_7_, lean_object* v_b_8_){
_start:
{
lean_object* v_res_9_; 
v_res_9_ = lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7(v_acc_7_, v_b_8_);
lean_dec(v_b_8_);
lean_dec(v_acc_7_);
return v_res_9_;
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec(lean_object* v_x_10_, lean_object* v_x_11_, lean_object* v_x_12_){
_start:
{
if (lean_obj_tag(v_x_11_) == 0)
{
lean_object* v___x_13_; 
v___x_13_ = lean_box(0);
return v___x_13_;
}
else
{
lean_object* v_head_14_; lean_object* v_tail_15_; lean_object* v___x_17_; uint8_t v_isShared_18_; uint8_t v_isSharedCheck_60_; 
v_head_14_ = lean_ctor_get(v_x_11_, 0);
v_tail_15_ = lean_ctor_get(v_x_11_, 1);
v_isSharedCheck_60_ = !lean_is_exclusive(v_x_11_);
if (v_isSharedCheck_60_ == 0)
{
v___x_17_ = v_x_11_;
v_isShared_18_ = v_isSharedCheck_60_;
goto v_resetjp_16_;
}
else
{
lean_inc(v_tail_15_);
lean_inc(v_head_14_);
lean_dec(v_x_11_);
v___x_17_ = lean_box(0);
v_isShared_18_ = v_isSharedCheck_60_;
goto v_resetjp_16_;
}
v_resetjp_16_:
{
lean_object* v_zero_19_; uint8_t v_isZero_20_; 
v_zero_19_ = lean_unsigned_to_nat(0u);
v_isZero_20_ = lean_nat_dec_eq(v_x_10_, v_zero_19_);
if (v_isZero_20_ == 1)
{
lean_object* v___x_21_; 
lean_del_object(v___x_17_);
lean_dec(v_tail_15_);
lean_dec(v_head_14_);
v___x_21_ = lean_box(0);
return v___x_21_;
}
else
{
lean_object* v_one_22_; lean_object* v_n_23_; uint8_t v_isZero_24_; 
v_one_22_ = lean_unsigned_to_nat(1u);
v_n_23_ = lean_nat_sub(v_x_10_, v_one_22_);
v_isZero_24_ = lean_nat_dec_eq(v_n_23_, v_zero_19_);
if (v_isZero_24_ == 1)
{
lean_object* v___x_25_; lean_object* v___x_26_; lean_object* v___x_27_; lean_object* v___x_29_; 
lean_dec(v_n_23_);
lean_dec(v_tail_15_);
v___x_25_ = lean_unsigned_to_nat(256u);
v___x_26_ = lean_nat_mul(v_x_12_, v___x_25_);
v___x_27_ = lean_nat_add(v___x_26_, v_head_14_);
lean_dec(v_head_14_);
lean_dec(v___x_26_);
if (v_isShared_18_ == 0)
{
lean_ctor_set_tag(v___x_17_, 0);
lean_ctor_set(v___x_17_, 1, v_one_22_);
lean_ctor_set(v___x_17_, 0, v___x_27_);
v___x_29_ = v___x_17_;
goto v_reusejp_28_;
}
else
{
lean_object* v_reuseFailAlloc_31_; 
v_reuseFailAlloc_31_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_31_, 0, v___x_27_);
lean_ctor_set(v_reuseFailAlloc_31_, 1, v_one_22_);
v___x_29_ = v_reuseFailAlloc_31_;
goto v_reusejp_28_;
}
v_reusejp_28_:
{
lean_object* v___x_30_; 
v___x_30_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_30_, 0, v___x_29_);
return v___x_30_;
}
}
else
{
lean_object* v_nv_32_; lean_object* v___x_33_; uint8_t v___x_34_; 
v_nv_32_ = lp_urings__http__kit__proof_UringsHttpKitProof_Varint_step7(v_x_12_, v_head_14_);
v___x_33_ = lean_unsigned_to_nat(128u);
v___x_34_ = lean_nat_dec_lt(v_head_14_, v___x_33_);
lean_dec(v_head_14_);
if (v___x_34_ == 0)
{
lean_object* v_n_35_; lean_object* v___x_36_; lean_object* v___x_37_; 
lean_del_object(v___x_17_);
v_n_35_ = lean_nat_sub(v_n_23_, v_one_22_);
lean_dec(v_n_23_);
v___x_36_ = lean_nat_add(v_n_35_, v_one_22_);
lean_dec(v_n_35_);
v___x_37_ = lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec(v___x_36_, v_tail_15_, v_nv_32_);
lean_dec(v_nv_32_);
lean_dec(v___x_36_);
if (lean_obj_tag(v___x_37_) == 0)
{
return v___x_37_;
}
else
{
lean_object* v_val_38_; lean_object* v___x_40_; uint8_t v_isShared_41_; uint8_t v_isSharedCheck_55_; 
v_val_38_ = lean_ctor_get(v___x_37_, 0);
v_isSharedCheck_55_ = !lean_is_exclusive(v___x_37_);
if (v_isSharedCheck_55_ == 0)
{
v___x_40_ = v___x_37_;
v_isShared_41_ = v_isSharedCheck_55_;
goto v_resetjp_39_;
}
else
{
lean_inc(v_val_38_);
lean_dec(v___x_37_);
v___x_40_ = lean_box(0);
v_isShared_41_ = v_isSharedCheck_55_;
goto v_resetjp_39_;
}
v_resetjp_39_:
{
lean_object* v_fst_42_; lean_object* v_snd_43_; lean_object* v___x_45_; uint8_t v_isShared_46_; uint8_t v_isSharedCheck_54_; 
v_fst_42_ = lean_ctor_get(v_val_38_, 0);
v_snd_43_ = lean_ctor_get(v_val_38_, 1);
v_isSharedCheck_54_ = !lean_is_exclusive(v_val_38_);
if (v_isSharedCheck_54_ == 0)
{
v___x_45_ = v_val_38_;
v_isShared_46_ = v_isSharedCheck_54_;
goto v_resetjp_44_;
}
else
{
lean_inc(v_snd_43_);
lean_inc(v_fst_42_);
lean_dec(v_val_38_);
v___x_45_ = lean_box(0);
v_isShared_46_ = v_isSharedCheck_54_;
goto v_resetjp_44_;
}
v_resetjp_44_:
{
lean_object* v___x_47_; lean_object* v___x_49_; 
v___x_47_ = lean_nat_add(v_snd_43_, v_one_22_);
lean_dec(v_snd_43_);
if (v_isShared_46_ == 0)
{
lean_ctor_set(v___x_45_, 1, v___x_47_);
v___x_49_ = v___x_45_;
goto v_reusejp_48_;
}
else
{
lean_object* v_reuseFailAlloc_53_; 
v_reuseFailAlloc_53_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_53_, 0, v_fst_42_);
lean_ctor_set(v_reuseFailAlloc_53_, 1, v___x_47_);
v___x_49_ = v_reuseFailAlloc_53_;
goto v_reusejp_48_;
}
v_reusejp_48_:
{
lean_object* v___x_51_; 
if (v_isShared_41_ == 0)
{
lean_ctor_set(v___x_40_, 0, v___x_49_);
v___x_51_ = v___x_40_;
goto v_reusejp_50_;
}
else
{
lean_object* v_reuseFailAlloc_52_; 
v_reuseFailAlloc_52_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_52_, 0, v___x_49_);
v___x_51_ = v_reuseFailAlloc_52_;
goto v_reusejp_50_;
}
v_reusejp_50_:
{
return v___x_51_;
}
}
}
}
}
}
else
{
lean_object* v___x_57_; 
lean_dec(v_n_23_);
lean_dec(v_tail_15_);
if (v_isShared_18_ == 0)
{
lean_ctor_set_tag(v___x_17_, 0);
lean_ctor_set(v___x_17_, 1, v_one_22_);
lean_ctor_set(v___x_17_, 0, v_nv_32_);
v___x_57_ = v___x_17_;
goto v_reusejp_56_;
}
else
{
lean_object* v_reuseFailAlloc_59_; 
v_reuseFailAlloc_59_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_59_, 0, v_nv_32_);
lean_ctor_set(v_reuseFailAlloc_59_, 1, v_one_22_);
v___x_57_ = v_reuseFailAlloc_59_;
goto v_reusejp_56_;
}
v_reusejp_56_:
{
lean_object* v___x_58_; 
v___x_58_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_58_, 0, v___x_57_);
return v___x_58_;
}
}
}
}
}
}
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec___boxed(lean_object* v_x_61_, lean_object* v_x_62_, lean_object* v_x_63_){
_start:
{
lean_object* v_res_64_; 
v_res_64_ = lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec(v_x_61_, v_x_62_, v_x_63_);
lean_dec(v_x_63_);
lean_dec(v_x_61_);
return v_res_64_;
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decode(lean_object* v_buf_65_){
_start:
{
lean_object* v___x_66_; lean_object* v___x_67_; lean_object* v___x_68_; 
v___x_66_ = lean_unsigned_to_nat(9u);
v___x_67_ = lean_unsigned_to_nat(0u);
v___x_68_ = lp_urings__http__kit__proof_UringsHttpKitProof_Varint_decodeSpec(v___x_66_, v_buf_65_, v___x_67_);
return v___x_68_;
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof___private_UringsHttpKitProof_0__UringsHttpKitProof_Varint_decodeSpec_match__1_splitter___redArg(lean_object* v_x_69_, lean_object* v_x_70_, lean_object* v_x_71_, lean_object* v_h__1_72_, lean_object* v_h__2_73_, lean_object* v_h__3_74_, lean_object* v_h__4_75_){
_start:
{
if (lean_obj_tag(v_x_70_) == 0)
{
lean_object* v___x_76_; 
lean_dec(v_h__4_75_);
lean_dec(v_h__3_74_);
lean_dec(v_h__2_73_);
v___x_76_ = lean_apply_2(v_h__1_72_, v_x_69_, v_x_71_);
return v___x_76_;
}
else
{
lean_object* v_head_77_; lean_object* v_tail_78_; lean_object* v_zero_79_; uint8_t v_isZero_80_; 
lean_dec(v_h__1_72_);
v_head_77_ = lean_ctor_get(v_x_70_, 0);
lean_inc(v_head_77_);
v_tail_78_ = lean_ctor_get(v_x_70_, 1);
lean_inc(v_tail_78_);
lean_dec_ref_known(v_x_70_, 2);
v_zero_79_ = lean_unsigned_to_nat(0u);
v_isZero_80_ = lean_nat_dec_eq(v_x_69_, v_zero_79_);
if (v_isZero_80_ == 1)
{
lean_object* v___x_81_; 
lean_dec(v_h__4_75_);
lean_dec(v_h__3_74_);
lean_dec(v_x_69_);
v___x_81_ = lean_apply_3(v_h__2_73_, v_head_77_, v_tail_78_, v_x_71_);
return v___x_81_;
}
else
{
lean_object* v_one_82_; lean_object* v_n_83_; uint8_t v_isZero_84_; 
lean_dec(v_h__2_73_);
v_one_82_ = lean_unsigned_to_nat(1u);
v_n_83_ = lean_nat_sub(v_x_69_, v_one_82_);
lean_dec(v_x_69_);
v_isZero_84_ = lean_nat_dec_eq(v_n_83_, v_zero_79_);
if (v_isZero_84_ == 1)
{
lean_object* v___x_85_; 
lean_dec(v_n_83_);
lean_dec(v_h__4_75_);
v___x_85_ = lean_apply_3(v_h__3_74_, v_head_77_, v_tail_78_, v_x_71_);
return v___x_85_;
}
else
{
lean_object* v_n_86_; lean_object* v___x_87_; 
lean_dec(v_h__3_74_);
v_n_86_ = lean_nat_sub(v_n_83_, v_one_82_);
lean_dec(v_n_83_);
v___x_87_ = lean_apply_4(v_h__4_75_, v_n_86_, v_head_77_, v_tail_78_, v_x_71_);
return v___x_87_;
}
}
}
}
}
LEAN_EXPORT lean_object* lp_urings__http__kit__proof___private_UringsHttpKitProof_0__UringsHttpKitProof_Varint_decodeSpec_match__1_splitter(lean_object* v_motive_88_, lean_object* v_x_89_, lean_object* v_x_90_, lean_object* v_x_91_, lean_object* v_h__1_92_, lean_object* v_h__2_93_, lean_object* v_h__3_94_, lean_object* v_h__4_95_){
_start:
{
if (lean_obj_tag(v_x_90_) == 0)
{
lean_object* v___x_96_; 
lean_dec(v_h__4_95_);
lean_dec(v_h__3_94_);
lean_dec(v_h__2_93_);
v___x_96_ = lean_apply_2(v_h__1_92_, v_x_89_, v_x_91_);
return v___x_96_;
}
else
{
lean_object* v_head_97_; lean_object* v_tail_98_; lean_object* v_zero_99_; uint8_t v_isZero_100_; 
lean_dec(v_h__1_92_);
v_head_97_ = lean_ctor_get(v_x_90_, 0);
lean_inc(v_head_97_);
v_tail_98_ = lean_ctor_get(v_x_90_, 1);
lean_inc(v_tail_98_);
lean_dec_ref_known(v_x_90_, 2);
v_zero_99_ = lean_unsigned_to_nat(0u);
v_isZero_100_ = lean_nat_dec_eq(v_x_89_, v_zero_99_);
if (v_isZero_100_ == 1)
{
lean_object* v___x_101_; 
lean_dec(v_h__4_95_);
lean_dec(v_h__3_94_);
lean_dec(v_x_89_);
v___x_101_ = lean_apply_3(v_h__2_93_, v_head_97_, v_tail_98_, v_x_91_);
return v___x_101_;
}
else
{
lean_object* v_one_102_; lean_object* v_n_103_; uint8_t v_isZero_104_; 
lean_dec(v_h__2_93_);
v_one_102_ = lean_unsigned_to_nat(1u);
v_n_103_ = lean_nat_sub(v_x_89_, v_one_102_);
lean_dec(v_x_89_);
v_isZero_104_ = lean_nat_dec_eq(v_n_103_, v_zero_99_);
if (v_isZero_104_ == 1)
{
lean_object* v___x_105_; 
lean_dec(v_n_103_);
lean_dec(v_h__4_95_);
v___x_105_ = lean_apply_3(v_h__3_94_, v_head_97_, v_tail_98_, v_x_91_);
return v___x_105_;
}
else
{
lean_object* v_n_106_; lean_object* v___x_107_; 
lean_dec(v_h__3_94_);
v_n_106_ = lean_nat_sub(v_n_103_, v_one_102_);
lean_dec(v_n_103_);
v___x_107_ = lean_apply_4(v_h__4_95_, v_n_106_, v_head_97_, v_tail_98_, v_x_91_);
return v___x_107_;
}
}
}
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
void lean_initialize_runtime_module();
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_urings__http__kit__proof_UringsHttpKitProof(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
lean_initialize_runtime_module();
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
