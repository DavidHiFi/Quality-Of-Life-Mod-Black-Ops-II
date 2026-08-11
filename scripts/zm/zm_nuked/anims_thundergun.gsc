#using_animtree("zm_nuked_basic");

reference_anims_from_animtree()
{
    dummy_anim_ref = %ai_zombie_thundergun_hit_armslegsforward;
    dummy_anim_ref = %ai_zombie_thundergun_hit_doublebounce;
    dummy_anim_ref = %ai_zombie_thundergun_hit_forwardtoface;
    dummy_anim_ref = %ai_zombie_thundergun_hit_stumblefall;
    dummy_anim_ref = %ai_zombie_thundergun_hit_upontoback;
    dummy_anim_ref = %ai_zombie_thundergun_hit_deadfallknee;
    dummy_anim_ref = %ai_zombie_thundergun_hit_flatonback;
    dummy_anim_ref = %ai_zombie_thundergun_hit_legsout_right;
    dummy_anim_ref = %ai_zombie_thundergun_hit_legsout_left;
    dummy_anim_ref = %ai_zombie_thundergun_hit_faceplant;
    dummy_anim_ref = %ai_zombie_thundergun_getup;
    dummy_anim_ref = %ai_zombie_thundergun_getup_a;
    dummy_anim_ref = %ai_zombie_thundergun_getup_b;
    dummy_anim_ref = %ai_zombie_thundergun_getup_c;
    dummy_anim_ref = %ai_zombie_thundergun_getup_quick_b;
    dummy_anim_ref = %ai_zombie_thundergun_getup_quick_c;
    dummy_anim_ref = %ai_zombie_thundergun_hit_jackiespin_right;
    dummy_anim_ref = %ai_zombie_thundergun_hit_jackiespin_left;
}

init() {
    level thread reference_anims_from_animtree();
}