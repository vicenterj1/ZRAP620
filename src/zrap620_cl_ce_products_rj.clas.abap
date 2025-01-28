CLASS zrap620_cl_ce_products_rj DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_rap_query_provider .

    TYPES t_product_range TYPE RANGE OF zrap620_sc_products_RJ=>tys_sepmra_i_product_etype.
    TYPES t_business_data TYPE zrap620_sc_products_RJ=>tyt_sepmra_i_product_etype.
    TYPES t_business_data_external type TABLE of zrap620_ce_products_rj.

    METHODS get_products
      IMPORTING
        it_filter_cond   TYPE if_rap_query_filter=>tt_name_range_pairs   OPTIONAL
        top              TYPE i OPTIONAL
        skip             TYPE i OPTIONAL
      EXPORTING
        et_business_data TYPE  t_business_data
      RAISING
        /iwbep/cx_cp_remote
        /iwbep/cx_gateway
        cx_web_http_client_error
        cx_http_dest_provider_error
      .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zrap620_cl_ce_products_rj IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  ENDMETHOD.
  METHOD get_products.

    DATA: filter_factory   TYPE REF TO /iwbep/if_cp_filter_factory,
          filter_node      TYPE REF TO /iwbep/if_cp_filter_node,
          root_filter_node TYPE REF TO /iwbep/if_cp_filter_node.

    DATA: http_client        TYPE REF TO if_web_http_client,
          odata_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
          read_list_request  TYPE REF TO /iwbep/if_cp_request_read_list,
          read_list_response TYPE REF TO /iwbep/if_cp_response_read_lst.

    DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = 'https://sapes5.sapdevcenter.com' ).
    http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

     odata_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
       EXPORTING
          is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                              proxy_model_id      = 'ZRAP620_SC_PRODUCTS_RJ'
                                              proxy_model_version = '0001' )
         io_http_client             = http_client
         iv_relative_service_root   = '/sap/opu/odata/sap/ZPDCDS_SRV/' ).

    " Navigate to the resource and create a request for the read operation
    read_list_request = odata_client_proxy->create_resource_for_entity_set( 'SEPMRA_I_PRODUCT_E' )->create_request_for_read( ).

    " Create the filter tree
    filter_factory = read_list_request->create_filter_factory( ).
    LOOP AT  it_filter_cond  INTO DATA(filter_condition).
      filter_node  = filter_factory->create_by_range( iv_property_path     = filter_condition-name
                                                              it_range     = filter_condition-range ).
      IF root_filter_node IS INITIAL.
        root_filter_node = filter_node.
      ELSE.
        root_filter_node = root_filter_node->and( filter_node ).
      ENDIF.
    ENDLOOP.

    IF root_filter_node IS NOT INITIAL.
      read_list_request->set_filter( root_filter_node ).
    ENDIF.

    IF top > 0 .
      read_list_request->set_top( top ).
    ENDIF.

    read_list_request->set_skip( skip ).

    " Execute the request and retrieve the business data
    read_list_response = read_list_request->execute( ).
    read_list_response->get_business_data( IMPORTING et_business_data = et_business_data ).

  ENDMETHOD.

METHOD if_rap_query_provider~select.
    DATA business_data TYPE t_business_data.
    DATA business_data_external TYPE t_business_data_external.
    DATA(top)     = io_request->get_paging( )->get_page_size( ).
    DATA(skip)    = io_request->get_paging( )->get_offset( ).
    DATA(requested_fields)  = io_request->get_requested_elements( ).
    DATA(sort_order)    = io_request->get_sort_elements( ).

    TRY.
        DATA(filter_condition) = io_request->get_filter( )->get_as_ranges( ).

        get_products(
                 EXPORTING
                   it_filter_cond    = filter_condition
                   top               = CONV i( top )
                   skip              = CONV i( skip )
                 IMPORTING
                   et_business_data  = business_data
                 ) .

        business_data_external = CORRESPONDING #( business_data
                                          MAPPING Product = product
                                                  ProductCategory = product_category
                                                  Supplier = supplier
                                                   ).

        io_response->set_total_number_of_records( lines( business_data_external ) ).
        io_response->set_data( business_data_external ).

      CATCH cx_root INTO DATA(exception).
        DATA(exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).
    ENDTRY.
  ENDMETHOD.


ENDCLASS.
