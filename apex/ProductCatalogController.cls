public with sharing class ProductCatalogController {

    /**
     * Devuelve todas las listas de precio (Pricebook2) activas.
     */
    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getActivePricebooks() {
        return [
            SELECT Id, Name
            FROM Pricebook2
            WHERE IsActive = true
            ORDER BY Name
        ];
    }

    /**
     * Obtiene los productos (PricebookEntry) activos de un Pricebook concreto.
     * @param pricebookId Id del Pricebook seleccionado.
     * @return Lista de PricebookEntry con datos de producto y precio.
     */
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProductsByPricebookId(Id pricebookId) {
        if (pricebookId == null) {
            throw new AuraHandledException('Debe indicar el Id del Price Book.');
        }

        return [
            SELECT Id,
                   Name,
                   UnitPrice,
                   IsActive,
                   Product2.Id,
                   Product2.Name,
                   Product2.Description,
                   Pricebook2.Name
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
              AND IsActive = true
            ORDER BY Product2.Name
        ];
    }

    /**
     * Añade un producto (PricebookEntry) a una Opportunity existente.
     * @param oppId Id de la Opportunity.
     * @param pricebookEntryId Id del PricebookEntry (producto con precio).
     * @param quantity Cantidad del producto.
     * @return Id del OpportunityLineItem creado.
     */
    @AuraEnabled
    public static Id addProductToOpportunity(Id oppId, Id pricebookEntryId, Decimal quantity) {
        if (oppId == null || pricebookEntryId == null || quantity == null || quantity <= 0) {
            throw new AuraHandledException('Debe indicar Opportunity, producto y cantidad válidos.');
        }

        // Obtener el precio unitario del producto
        PricebookEntry pbe = [
            SELECT UnitPrice
            FROM PricebookEntry
            WHERE Id = :pricebookEntryId
            LIMIT 1
        ];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId    = oppId,
            PricebookEntryId = pricebookEntryId,
            Quantity         = quantity,
            UnitPrice        = pbe.UnitPrice // dejamos que Salesforce calcule el TotalPrice
        );

    insert oli;

    return oli.Id;
}

   /**
     * Crea un OpportunityLineItem dado un producto y un precio,
     * resolviendo el PricebookEntry correcto según el Pricebook de la Opportunity.
     */
    @AuraEnabled
    public static Id createOpportunityLineItem(Id opportunityId, Id productId, Decimal unitPrice) {
        if (opportunityId == null || productId == null || unitPrice == null || unitPrice <= 0) {
            throw new AuraHandledException('Debe indicar Opportunity, producto y precio válidos.');
        }

        // Obtener el Pricebook asignado a la oportunidad
        Opportunity opp = [
            SELECT Pricebook2Id
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp.Pricebook2Id == null) {
            throw new AuraHandledException('La oportunidad no tiene lista de precios asignada.');
        }

        // Buscar el PricebookEntry del producto en la lista de precios de la oportunidad
        PricebookEntry pbe = [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2Id = :productId
              AND Pricebook2Id = :opp.Pricebook2Id
              AND IsActive = true
            LIMIT 1
        ];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId    = opportunityId,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = unitPrice
        );

        insert oli;

        return oli.Id;
    }
}
