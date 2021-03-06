{
    package Slides;
    $VERSION = 0.1;

    use warnings;
    use strict;

    use IO::Dir;
    use File::Basename        qw(dirname);
    use File::Spec::Functions qw(catfile rel2abs);

    use constant SLIDEFILE => qr/^[0-9]{2}-(.*)\.yaml$/;
    use constant SLIDEPATH => catfile(
        dirname(dirname(rel2abs(__FILE__))), 'slides'
    );

    use Slide;
    use Slide::Keys;
    use Slide::Functions;

    our ($slides, $indexes, $slide, $in_listing);

    sub load {
        my ($dir) = IO::Dir->new(SLIDEPATH);

        $slides  = {};
        while (my $file = $dir->read) {
            if ($file =~ SLIDEFILE) {
                $slides->{$file} = Slide->new($file);
            }
        }

        $indexes = [ sort keys %{ $slides } ];
    }

    sub start {
        rightnow("echo '' > slides/current-slide.md" . ENTER);
        rightnow("vi slides/current-slide.md" . ENTER);
    }

    sub full_reset {
        VIM::DoCommand('source controller.vim');
        finish_presentation();
        $slide = undef;

        advance();
    }

    sub ensure_started {
        unless (defined $slide) {
            start();
            $slide = 0;
        }
    }

    sub go_to_slide {
        ($slide) = @_;
        $slide--; # we're expecting "Slide 1" to map to $indexes->[0]

        ensure_started();

        foreach my $name (@{ $indexes }[$slide .. $#{ $indexes }]) {
            $slides->{ $name }->reset();
        }

        slide()->next;
    }

    sub display_list {
        ensure_started();

        Slide::clear_buffer();
        Slide::set_filetype('text');
        slide()->reset;

        rightnow(INSERT);

        for (my $index = 0; $index <= $#{ $indexes }; $index++) {
            my ($name) = $indexes->[$index];

            if ($index == $slide) {
                rightnow('(*) ');
            }
            else {
                rightnow('( ) ');
            }

            $name =~ SLIDEFILE;
            rightnow(sprintf('%02d. %s', ($index + 1), $1) . ENTER);
        }
        rightnow(ESC);
    }

    sub slide {
        return if $slide > $#{ $indexes };
        $slides->{ $indexes->[$slide] };
    }

    sub advance {
        ensure_started();
        $slide++ if slide()->finished;

        if (slide()) {
            slide()->next;
        }
        else {
            finish_presentation();
        }
    }

    sub finish_presentation {
        rightnow(ESC . ':q!' . ENTER . 'clear' . ENTER);
    }

    our $__SELF__ = __PACKAGE__
}
