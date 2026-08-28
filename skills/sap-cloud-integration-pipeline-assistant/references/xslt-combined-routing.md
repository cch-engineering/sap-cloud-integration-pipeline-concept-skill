# Combined Receiver and Interface Determination XSLT

For integrated async recipient-list routing, preserve the expected XI namespace and complete output hierarchy. The following structure is the validated user-supplied pattern. Adapt only source XPath, receiver aliases, names, and Step07 addresses.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <ns0:Receivers xmlns:ns0="http://sap.com/xi/XI/System">
      <ReceiverNotDetermined>
        <Type>Error</Type>
        <DefaultReceiver/>
      </ReceiverNotDetermined>
      <xsl:if test="/*:MaintenanceOrder/MaintenanceOrderType/MaintenanceOrderType = 'YBA1'">
        <Receiver>
          <Service>Receiver_AssetRegistry</Service>
          <Interfaces>
            <Interface>
              <Index>1</Index>
              <Name>SI_MaintenanceOrder_To_AssetRegistry</Name>
              <Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_AssetRegistry</Service>
            </Interface>
          </Interfaces>
        </Receiver>
        <Receiver>
          <Service>Receiver_Crow</Service>
          <Interfaces>
            <Interface>
              <Index>1</Index>
              <Name>SI_MaintenanceOrder_To_Crow</Name>
              <Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_Crow</Service>
            </Interface>
          </Interfaces>
        </Receiver>
      </xsl:if>
    </ns0:Receivers>
  </xsl:template>
</xsl:stylesheet>
```

Rules:
- Multiple `Receiver` nodes implement a recipient list.
- Multiple `Interface` nodes implement interface split for a receiver.
- `Service` under `Receiver` is the receiver alias.
- `Service` under `Interface` is the Step07 ProcessDirect address in this pattern.
- `Index` under `Interface` is extracted to header `SAP_ReceiverInterfaceIndex` for MPL monitoring only. It does NOT control execution order. Order is determined by document order of `<Interface>` nodes in the XML.
- `Name` under `Interface` is extracted to header `SAP_ReceiverInterface` for MPL monitoring. Always include it; omitting it leaves `SAP_ReceiverInterface` empty in MPL.
- **Maintained order at runtime limitation**: The generic Step05 iterating splitter processes `<Interface>` nodes sequentially in document order and stops on failure, but on retry it replays from the first node — risking duplicate delivery. When maintained order AND idempotent per-interface delivery on retry are required, implement a Sequential Multicast + Idempotent Process Call pattern in Step07 instead of relying solely on Step05. Reference: `PIPSamplesScenario3_Step07_RCV1_InOrder`.
- Select Error, Ignore, or Default deliberately in `<ReceiverNotDetermined><Type>` and explain runtime consequences. The receiver determination step also reads PD String Parameters `ReceiverNotDeterminedType` (default: `Error`) and `ReceiverNotDeterminedDefault` (fallback alias when type = `Default`); validate which takes precedence in your deployed package.
