# Histórico do item de inventário

Um item de inventário agora possui um histórico com algumas ações importantes que ocorrem.

## Listar histórico

O endpoint para listagem/busca é: `GET /inventory/items/:id/history`, caso não passe nenhum parâmetro de filtro, retornará todos as entradas de histórico paginada (por padrão 25 itens por página).

Os parâmetros/filtros aceitos são:

| Nome       | Tipo    | Obrigatório | Descrição                                                                              |
|------------|---------|-------------|----------------------------------------------------------------------------------------|
| user_id    | Integer | Não         | O id do usuário que deseja filtrar                                                     |
| kind       | String  | Não         | O tipo da ação, pode ser: 'report', 'fields', 'images', 'flow', 'formula' ou 'status'. |
| created_at | Object  | Não         | Objeto com 'begin' e/ou 'end' com datas em formato ISO-8601 para filtrar.              |
| object_id | Integer  | Não         | ID do objeto relacionado ao histórico              |

Exemplo de parâmetros:

    /inventory/items/90/history?user_id=1&kind=report

Exemplo de retorno:

    {
      histories: [{
        "id": 1,
        "inventory_item_id": 90,
        "user": {
          "id": 1,
          "name": "Ellie Welch IV",
          "groups": [...],
          "permissions": {...},
          "groups_names": [
            "Administradores"
          ]
        },
        "kind": "report",
        "action": "Um relato foi solicitado",
        "objects": [],
        "created_at": "2015-02-23T22:17:56.257-03:00"
      }, ...]
    }
