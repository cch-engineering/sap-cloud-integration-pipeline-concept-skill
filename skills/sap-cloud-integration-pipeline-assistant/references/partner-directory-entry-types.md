# Partner Directory Entry Types and Output Templates

## Alternative Partner
- Partner ID: `<ConfigurationScenarioPid>`
- Entry type: Alternative Partner
- Location: Monitor > Integrations and APIs > Partner Directory > Partner > Alternative Partners
- Purpose: Resolve sender/interface (with or without namespace) to the configuration scenario PID

### Without namespace (`SAP_SenderInterfaceNamespace` not set in Step01)
- Agency: `<SenderAlias>` (e.g. `S4HANA`)
- Scheme: `SenderInterface`
- Identifier: `<SenderInterface>` (e.g. `SI_Order_Out_Async`)

JSON:
```json
{
  "Pid": "<ConfigurationScenarioPid>",
  "Agency": "<SenderAlias>",
  "Scheme": "SenderInterface",
  "Id": "<SenderInterface>"
}
```

### With namespace (`SAP_SenderInterfaceNamespace` set in Step01, e.g. `http://abc.com`)
- Agency: `<SenderAlias>` (e.g. `S4HANA`)
- Scheme: `<SenderInterface>` (e.g. `SI_Order_Out_Async`)
- Identifier: `<namespace>` (e.g. `http://abc.com`)

JSON:
```json
{
  "Pid": "<ConfigurationScenarioPid>",
  "Agency": "<SenderAlias>",
  "Scheme": "<SenderInterface>",
  "Id": "<namespace>"
}
```

Always ask the user whether a namespace is present before generating the Alternative Partner entry. The two structures are not interchangeable.

## String Parameter
- Partner ID: `<ConfigurationScenarioPid>`
- Entry type: String Parameter
- Location: Partner Directory > Partner > String Parameters
- Parameter ID: `<ParameterName>`
- Value: `<Value>`
- Purpose: Runtime configuration or bypass value

## Binary Parameter
- Partner ID: `<ConfigurationScenarioPid>`
- Entry type: Binary Parameter
- Location: Partner Directory > Partner > Binary Parameters
- Parameter ID: `receiverDetermination` or documented ID
- Content type: `xsl`
- File/content: `<Mapping.xsl>`
- Purpose: Receiver or combined receiver/interface determination

## Authorized User
- Partner ID: `Landscape_Stage~<Stage>`
- Entry type: Authorized User
- Location: Partner Directory > Partner > Authorized Users
- User: `<OAuthClientIdOrAuthenticatedUser>`
- Purpose: Resolve authenticated caller to virtual stage
- Constraint: Do not map the same authorized user to multiple partners

## Partner container
A Partner ID is the container. Creating a partner alone does not create routing. Always list the Alternative Partner, String Parameter, Binary Parameter, and Authorized User children needed inside it.
