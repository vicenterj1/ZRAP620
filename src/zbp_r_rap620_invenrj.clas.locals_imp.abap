CLASS LHC_ZR_RAP620_INVENRJ DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    DATA gv_url TYPE string
     VALUE 'https://sapes5.sapdevcenter.com/sap/bc/srt/xip/sap/zepm_product_soap/002/epm_product_soap/epm_product_soap'.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR Inventory
        RESULT result,
      CalculateInventoryID FOR DETERMINE ON SAVE
            IMPORTING keys FOR Inventory~CalculateInventoryID,
      GetPrice FOR DETERMINE ON MODIFY
            IMPORTING keys FOR Inventory~GetPrice.
ENDCLASS.

CLASS LHC_ZR_RAP620_INVENRJ IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD CalculateInventoryID.
  "Ensure idempotence
   " READ ENTITIES OF zrap620_r_inventorytp_### IN LOCAL MODE
   read ENTITIES OF ZR_RAP620_INVENRJ in LOCAL MODE
      ENTITY Inventory
        FIELDS ( InventoryID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(inventories).

    DELETE inventories WHERE InventoryID IS NOT INITIAL.
    CHECK inventories IS NOT INITIAL.

    "Get max travelID
    SELECT SINGLE FROM zrap620_invenrj FIELDS MAX( inventory_id ) INTO @DATA(max_inventory).

    "update involved instances
    "MODIFY ENTITIES OF zrap620_r_inventorytp_### IN LOCAL MODE
   MODIFY ENTITIES OF zr_rap620_invenrj in LOCAL MODE
     ENTITY Inventory
        UPDATE FIELDS ( InventoryID )
        WITH VALUE #( FOR inventory IN inventories INDEX INTO i (
                           %tky      = inventory-%tky
                           inventoryID  = max_inventory + i ) )
    REPORTED DATA(lt_reported).

    "fill reported
    reported = CORRESPONDING #( DEEP lt_reported ).
  ENDMETHOD.

METHOD GetPrice.
    DATA destination  TYPE REF TO if_soap_destination.
    DATA proxy TYPE REF TO zrap620rjco_epm_product_soap.
    DATA reported_inventory_soap LIKE reported-inventory.
    "Ensure idempotence
    READ ENTITIES OF ZR_RAP620_INVENRJ IN LOCAL MODE
      ENTITY Inventory
        FIELDS ( Price ProductID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(inventories).

    DELETE inventories WHERE Price IS NOT INITIAL.
    CHECK inventories IS NOT INITIAL.

    DELETE inventories WHERE ProductID =''.
    CHECK inventories IS NOT INITIAL.

   LOOP AT inventories ASSIGNING FIELD-SYMBOL(<fs_inventory>).

      TRY.

          IF destination IS INITIAL.
            destination = cl_soap_destination_provider=>create_by_url( i_url = gv_url ).
          ENDIF.
          IF proxy IS INITIAL.
            proxy = NEW zrap620RJco_epm_product_soap( destination = destination ).
          ENDIF.

          DATA(request) = VALUE zrap620RJreq_msg_type( req_msg_type-product = <fs_inventory>-ProductId  ).
          proxy->get_price(
            EXPORTING
              input = request
            IMPORTING
              output = DATA(response)
          ).

           <fs_inventory>-Price = response-res_msg_type-price .
           <fs_inventory>-CurrencyCode = response-res_msg_type-currency.
          "handle response

        CATCH cx_soap_destination_error INTO DATA(soap_destination_error).
          DATA(error_message) = soap_destination_error->get_text(  ).
        CATCH cx_ai_system_fault INTO DATA(ai_system_fault).
          error_message = | code: { ai_system_fault->code  } codetext: { ai_system_fault->codecontext  }  |.
        CATCH zrap620RJcx_fault_msg_type INTO DATA(soap_exception).
          error_message = soap_exception->error_text.
          "fill reported structure to be displayed on the UI
          APPEND VALUE #( uuid = <fs_inventory>-uuid
                          %msg = new_message( id = 'ZCM_RAP_GENERATOR'
                                              number = '016'
                                              v1 = error_message
                                              "v2 = messages[ 1 ]-msgv2
                                              "v3 = messages[ 1 ]-msgv3
                                              "v4 = messages[ 1 ]-msgv4
                                              severity = CONV #( 'E' ) )
                           %element-price = if_abap_behv=>mk-on


    ) TO reported_inventory_soap.
          "inventory entries where no price could be retrieved must not be passed to the MODIFY statement
          DELETE inventories INDEX sy-tabix.
      ENDTRY.

    ENDLOOP.

    "update involved instances
   "MODIFY ENTITIES OF zrap620_r_inventorytp_### IN LOCAL MODE
   MODIFY ENTITIES OF ZR_RAP620_INVENRJ IN LOCAL MODE
      ENTITY Inventory
        UPDATE FIELDS ( Price CurrencyCode )
        WITH VALUE #( FOR inventory IN inventories (
                           %tky      = inventory-%tky
                           Price  = inventory-Price
                           CurrencyCode  = inventory-CurrencyCode
                           ) )
    REPORTED DATA(reported_entities).

    "fill reported
    reported = CORRESPONDING #( DEEP reported_entities ).

    "add reported from SOAP call
    LOOP AT reported_inventory_soap INTO DATA(reported_inventory).
      APPEND reported_inventory TO reported-inventory.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
