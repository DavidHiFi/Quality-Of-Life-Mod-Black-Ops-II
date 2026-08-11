#using_animtree("zm_tomb_basic");

reference_anims_from_animtree()
{
    dummy_anim_ref = %ai_zombie_freeze_death_a;
    dummy_anim_ref = %ai_zombie_freeze_death_b;
    dummy_anim_ref = %ai_zombie_freeze_death_c;
    dummy_anim_ref = %ai_zombie_freeze_death_d;
    dummy_anim_ref = %ai_zombie_freeze_death_e;
    dummy_anim_ref = %ai_zombie_crawl_freeze_death_01;
    dummy_anim_ref = %ai_zombie_crawl_freeze_death_02;
}

init() {
    level thread reference_anims_from_animtree();
}