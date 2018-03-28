#Schema Registry Operations


## Connection URL

    $SCHEMA_REGISTRY_URL

## Schema Registry Queries

Check all registered subjects

    curl -X GET $SCHEMA_REGISTRY_URL/subjects

List versions of a subject

    curl -X GET $SCHEMA_REGISTRY_URL/subjects/null/versions

Get subject version

    curl -X GET $SCHEMA_REGISTRY_URL/subjects/null/versions/1

Get schmea by id

    curl -X GET $SCHEMA_REGISTRY_URL/schemas/ids/61

