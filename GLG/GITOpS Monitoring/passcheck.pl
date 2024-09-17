my $password=OjutoGtmqo3jZPIl+FpK69ahO0IjJkvzd5dRC+NQM9ipGnyXMnsEYIdQI7fs3WBU


sub get_Ers_password {
#    my $ersproperties = shift ;
#    $ersproperties ||= $cfg{"PRSPI_RUNTIMECONFIG"} . "/ErsConf.prop";
#    return unless ( -e $ersproperties );
    my $wordval;    #The return plain text value of the password

    # Read encrypted password
#    open( IN, "<$ersproperties" )
#      or FATAL( "unable to open the Ers file %s", $ersproperties );
#    while (<IN>) {
#        $line = $_;
#        chomp($line);
#        if ( $line =~ /ErsAdminPassword/ ) {
#            ( $a, $password ) = split( "=", $line );
#        }
#    }
#    close(IN);
    for ( $i = 0 ; $i < length($password) ; $i += 2 ) {
        $b1 = substr $password, $i, 1;
        $b2 = substr $password, $i + 1, 1;

        $upper     = ord($b1) - ord('A');
        $upper     = $upper * 16;
        $lower     = ord($b2) - ord('A');
        $numberval = $upper + $lower;
        my $charval = chr($numberval);
        $wordval = $wordval . $charval;
    }
    return ($wordval);
}

print get_Ers_password()