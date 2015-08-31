trigger PopulateX2tor_Program on Case (before insert) {
    for( Case c : Trigger.new ){
        if( c.origin == 'Email MAT' || c.origin == 'Case MAT' ){
            c.X2tor_Program__c = 'MAT';
        } else if( c.origin == 'Email MSW' || c.origin == 'Case MSW' ){
            c.X2tor_Program__c = 'MSW';
        } else if( c.origin == 'Email MBA' || c.origin == 'Case MBA' ){
            c.X2tor_Program__c = 'MBA';
        } else if( c.origin == 'Email MSN' || c.origin == 'Case MSN' ){
            c.X2tor_Program__c = 'MSN';
        } else if( c.origin == 'Email MPA' || c.origin == 'Case MPA' ){
            c.X2tor_Program__c = 'MPA';
        } else if( c.origin == 'Email LLM' || c.origin == 'Case LLM' ){
            c.X2tor_Program__c = 'LLM';
        } else if( c.origin == 'Email Hub' || c.origin == 'Case Hub' ){
            c.X2tor_Program__c = 'Hub';
        } else if( c.origin == 'Email crm@' ){
            c.X2tor_Program__c = 'MAT;MSW;MBA;MSN;MPA;LLM';
        }
    }
}