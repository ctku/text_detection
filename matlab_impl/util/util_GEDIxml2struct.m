function GEDI = util_GEDIxml2struct(xmlfile)

    tree = util_xml2struct(xmlfile);
    idx = util_xmlGetArrayIdxByName(tree, 'GEDI');
    gedi = tree(idx);
    GEDI.xmlns = util_xmlGetAttribValByName(gedi, 'xmlns');
    GEDI.GEDI_date = util_xmlGetAttribValByName(gedi, 'GEDI_date');
    GEDI.GEDI_version = util_xmlGetAttribValByName(gedi, 'GEDI_version');
    idx = util_xmlGetArrayIdxByChilName(gedi, 'DL_DOCUMENT');
    dl_doc = gedi.children(idx);
	DL_DOCUMENT.NrOfPages = util_xmlGetAttribValByName(dl_doc, 'NrOfPages');
	DL_DOCUMENT.docTag = util_xmlGetAttribValByName(dl_doc, 'docTag');
	DL_DOCUMENT.src = util_xmlGetAttribValByName(dl_doc, 'src');
    dl_page_no = (size(dl_doc.children,2)-1)/2;
    for p=1:dl_page_no;
        dl_page = dl_doc.children(2);
        DL_PAGE.gedi_type = util_xmlGetAttribValByName(dl_page, 'gedi_type');
        DL_PAGE.height = util_xmlGetAttribValByName(dl_page, 'height');  
        DL_PAGE.pageID = util_xmlGetAttribValByName(dl_page, 'pageID');
        DL_PAGE.src = util_xmlGetAttribValByName(dl_page, 'src');
        DL_PAGE.width = util_xmlGetAttribValByName(dl_page, 'width');
        dl_zone_no = (size(dl_page.children,2)-1)/2;
        for z=1:dl_zone_no
            dl_zone = dl_page.children(2*z);
            DL_ZONE(z).gedi_type = util_xmlGetAttribValByName(dl_zone, 'gedi_type');
            DL_ZONE(z).id = util_xmlGetAttribValByName(dl_zone, 'id');
            switch DL_ZONE(z).gedi_type
                case 'TEXTLINE'
                    DL_ZONE(z).contents = util_xmlGetAttribValByName(dl_zone, 'contents');
                    DL_ZONE(z).language = util_xmlGetAttribValByName(dl_zone, 'language');
                    DL_ZONE(z).polygon = util_xmlGetAttribValByName(dl_zone, 'polygon');
                    DL_ZONE(z).segmentation = util_xmlGetAttribValByName(dl_zone, 'segmentation');
                case 'NonChar_Region'
                    DL_ZONE(z).id = util_xmlGetAttribValByName(dl_zone, 'id');
                    DL_ZONE(z).col = util_xmlGetAttribValByName(dl_zone, 'col');
                    DL_ZONE(z).row = util_xmlGetAttribValByName(dl_zone, 'row');
                    DL_ZONE(z).width = util_xmlGetAttribValByName(dl_zone, 'width');
                    DL_ZONE(z).height = util_xmlGetAttribValByName(dl_zone, 'height');
                otherwise
                    warning('Unsupported gedi_type: %s', DL_ZONE(z).gedi_type);
                    assert(1==0);
            end

        end
    end
    
    % assemble output
    DL_PAGE.DL_ZONE = DL_ZONE;
    DL_DOCUMENT.DL_PAGE = DL_PAGE;
    GEDI.DL_DOCUMENT = DL_DOCUMENT;
end