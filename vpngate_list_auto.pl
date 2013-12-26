#!/usr/bin/env perl 
#===============================================================================
#         FILE: vpngate.pl
#       AUTHOR: YOUR NAME 
#      VERSION: 1.0
#      CREATED: 12/15/2013 08:30:02 PM
#===============================================================================

use strict;
use warnings;
use utf8;

use LWP;
use MIME::Base64;
use IO::Socket::PortState qw(check_ports);
use Smart::Comments;

### heroku����vpngage��cvs��ʽ��vpn server�б�
my $vpn_list = 'http://enigmatic-scrubland-4484.herokuapp.com/';

### get server list from list url
my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my $res = $ua->get($vpn_list);


# �ɹ������б�
my @vpns;
if ( $res->is_success ) {
    my @svrs = split /\n/, $res->content;
#    print $svrs[3], "\n";

    for my $server (@svrs) {
        next if $server =~ m/^#/;
        next if $server =~ m/\*/;

        my ($IP, $CountryShort, $OpenVPN_ConfigData_Base64) = ( split /,/, $server )[1,6,-1];
        my $openvpn_config = decode_base64($OpenVPN_ConfigData_Base64);

        # ��open vpn�������л�ȡTCP�˿ںţ�������ͨ��
        ### $IP
        ## $openvpn_config
        if ( $openvpn_config =~ m/^proto tcp/m ) {
            my ($port) = $openvpn_config =~ m/^remote [.|\d]+ (\d+)/m;
            ### $port
            my $porthash = {
                tcp => {
                    $port => {}
                }
            };
            my $timeout = 1;
            check_ports($IP, $timeout, $porthash);
            ### $porthash

            push @vpns, [$IP, $port, $openvpn_config];

        }

    }

    ### �����õ�vpn�����ļ�д��openvpn�������ļ�Ŀ¼���������
    ### д��ǰ��ɾ������openvpn����server���ã� rm *.ovpn

    my $open_conf_path = 'C:\Program Files\OpenVPN\config';
    chdir $open_conf_path or die "can't chdir to $open_conf_path";
    opendir my $df, $open_conf_path
        or die "can't open dir $open_conf_path";
    while (readdir $df) {
        if ( /^vpngate.*\.ovpn$/ ) {
            print "unlink $_\n";
            unlink $_ or warn "unlink $_ error:$!";
        }
    }

    for my $vpn (@vpns[0..3]) {
        my ($IP, $port, $openvpn_config) = @$vpn;
        my $filename = "vpngate_${IP}_${port}.ovpn";
        open my $fh, ">$filename"
            or die "can't open file $filename:$!";
        print $fh $openvpn_config;
        close $fh;
    }
    
}
else {
    warn "HTTP GET ERROR: ", $res->status_line;
}
