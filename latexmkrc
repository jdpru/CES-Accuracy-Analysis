# Build the other document first when one cites the other through xr
# (manuscript.tex <-> supplementary_material.tex). Works locally and on Overleaf.
add_cus_dep( 'tex', 'aux', 0, 'makeexternaldocument' );
sub makeexternaldocument {
    if (!($root_filename eq $_[0])) {
        system( "latexmk -cd -pdf \"$_[0]\"" );
    }
}
