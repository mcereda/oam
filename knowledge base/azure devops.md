# Azure Devops

## Table of contents <!-- omit in toc -->

1. [Pipelines](#pipelines)
   1. [Predefined variables](#predefined-variables)
   1. [Loops](#loops)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Pipelines

### Predefined variables

See [Use predefined variables] for more information.

### Loops

See [Expressions] for more information.

Use the `each` keyword to loop through **parameters of the object type**:

```yaml
parameters:
  - name: listOfFruits
    type: object
    default:
      - fruitName: 'apple'
        colors: ['red','green']
      - fruitName: 'lemon'
        colors: ['yellow']

steps:
  - ${{ each fruit in parameters.listOfFruits }} :
    - ${{ each fruitColor in fruit.colors}} :
      - script: echo ${{ fruit.fruitName}} ${{ fruitColor }}
```

## Further readings

- [Expressions]
- [Use predefined variables]

## Sources

All the references in the [further readings] section, plus the following:

- [Loops in Azure DevOps Pipelines]

<!-- project's references -->
[expressions]: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/expressions
[use predefined variables]: https://learn.microsoft.com/en-us/azure/devops/pipelines/build/variables

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[loops in azure devops pipelines]: https://pakstech.com/blog/azure-devops-loops/
