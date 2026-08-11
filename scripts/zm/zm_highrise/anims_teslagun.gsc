#using_animtree("zm_highrise_basic");

reference_anims_from_animtree()
{
    dummy_anim_ref = %ai_zombie_tesla_death_a;
    dummy_anim_ref = %ai_zombie_tesla_death_b;
    dummy_anim_ref = %ai_zombie_tesla_death_c;
    dummy_anim_ref = %ai_zombie_tesla_death_d;
    dummy_anim_ref = %ai_zombie_tesla_death_e;
    dummy_anim_ref = %ai_zombie_tesla_crawl_death_a;
    dummy_anim_ref = %ai_zombie_tesla_crawl_death_b;
}

init() {
    level thread reference_anims_from_animtree();
}