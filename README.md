# go 🚗🧭

**go** é um aplicativo de GPS e navegação turn-by-turn 100% offline, projetado para garantir viagens seguras e estáveis em áreas remotas do Brasil sem qualquer sinal de internet.

## Diferenciais

- **Mapas Modulares:** Suporte a download de pacotes de mapas offline por estado via arquivos `.mbtiles` e `.pmtiles` baseados no OpenStreetMap.
- **Roteamento A* Nativo (Offline):** O algoritmo A* (A-Star) é executado localmente. O motor puxa um subgrafo (ruas entre origem e destino) direto de um banco **SQLite** usando indexação espacial **R*Tree** (Bounding Box). Todo esse cálculo pesado roda em um `Isolate` dedicado, mantendo a interface sempre responsiva.
- **Modo HUD (Head-Up Display):** A tela de navegação inverte 180° para ser refletida diretamente no para-brisa do carro durante viagens à noite.
- **Pontos de Interesse & SOS:** Bases locais de PRF, borracharias e suporte 24h acessíveis sem rede.

## Arquitetura

O app utiliza o padrão **GetX** para gerenciamento de estado, rotas e injeção de dependência. A estrutura principal fica em `lib/app/`:
- `modules/`: Contém as telas (ex: Mapa, Navegação/HUD) separadas em Views, Controllers e Bindings.
- `data/`: O coração offline. Possui o `database_provider` para acesso ao SQLite e o `offline_routing_service` para matemática de rotas isolada.
- `routes/`: Mapeamento de rotas e declaração das páginas.

## Como Executar

```bash
# 1. Baixar as dependências
flutter pub get

# 2. Iniciar o aplicativo
flutter run
```
