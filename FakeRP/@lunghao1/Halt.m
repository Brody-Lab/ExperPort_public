function [] = Halt(lh1)
    
    lh1 = get_mylh1(lh1);
    lh1.running = 0;
    save_mylh1(lh1);
    check_statechange_callback(lh1);
    