# Transcriber (WhisperX via Docker – CPU)

Transcrição automática com WhisperX rodando 100% em CPU, empacotado em Docker para macOS (Apple Silicon/Intel) e quaisquer máquinas sem GPU. O fluxo é simples: coloque seus áudios na pasta `in/`, configure o `.env` e rode o serviço. Os resultados serão gravados em `out/`.

> Observação: este container está configurado para usar o modo CPU, com `--compute_type int8`, e inclui diarização de falantes. Em CPUs, a execução pode levar bastante tempo em modelos grandes.

## Requisitos

- Docker Desktop (macOS/Windows/Linux)
- Memória disponível: recomenda-se 12–16 GB para modelos médios e diarização
- Espaço em disco para cache de modelos (volume `whisper_cache`)
- (Opcional, mas recomendado para diarização/align) Token do Hugging Face: https://huggingface.co/settings/tokens

## Estrutura do projeto

```
.
├─ Dockerfile                # imagem Python + WhisperX
├─ docker-compose.yaml       # serviço 'transcribe' (CPU, diarização, cache)
├─ .env                      # variáveis de ambiente (não comitar segredos)
├─ in/                       # coloque aqui seus áudios (.m4a/.mp3/.wav...)
└─ out/                      # saídas (transcrições/legendas/JSON)
```

## Configuração (.env)

Crie (ou edite) um arquivo `.env` na raiz com as variáveis abaixo. Exemplo:

```
# Nome do arquivo de áudio dentro de /in (com extensão)
AUDIO=exemplo.m4a

# Modelo Whisper a usar: tiny, base, small, medium, large-v2
WHISPER_MODEL=small

# Código de idioma (ex.: pt, en, es, fr, de ...). Opcional.
# Se vazio, o WhisperX tentará detectar automaticamente.
AUDIO_LANG=

# Habilitar diarização (se 'true', usa modelos da HF e requer HF_TOKEN)
DIARIZE=false

# Faixa de falantes (usado apenas quando DIARIZE=true)
MIN_SPEAKERS=2
MAX_SPEAKERS=10

# Ajustes de performance (opcionais)
BATCH_SIZE=4
COMPUTE_TYPE=int8

# Token do Hugging Face (necessário para diarização)
HF_TOKEN=
```

Dicas de escolha do modelo (CPU):
- tiny/base: rápidos e leves, menor qualidade
- small: bom equilíbrio
- medium: melhor qualidade, bem mais lento
- large-v2: qualidade máxima, muito lento em CPU

## Como executar

1) Coloque seu arquivo de áudio em `in/` (ex.: `in/exemplo.m4a`).
2) Preencha o `.env` conforme acima.
3) Execute o container com Docker Compose.

Com build automático e execução do job:

```bash
# build + roda o serviço definido em docker-compose.yaml
docker compose up --build transcribe
```

Ou, se preferir executar como um job de uso único:

```bash
# opcional: construir a imagem explicitamente
docker compose build transcribe

# roda e remove o container após finalizar
docker compose run --rm transcribe
```

A saída será gravada em `out/`. O WhisperX normalmente gera transcrições e legendas (ex.: `.txt`, `.srt`, `.vtt`, `.json`), incluindo marcação de falantes quando a diarização está ativa.

## O que o Compose faz

O serviço `transcribe`:
- Monta volumes:
  - `./in` em `/in` (entrada)
  - `./out` em `/out` (saída)
  - volume nomeado `whisper_cache` em `/.cache` (cache de modelos)
- Define limites de memória e `shm_size` para estabilidade de PyTorch/FFmpeg
- Executa o comando (com flags condicionais por variáveis):

```bash
whisperx /in/${AUDIO} \
  --model ${WHISPER_MODEL} \
  [--language ${AUDIO_LANG} se definido] \
  [--diarize --hf_token ${HF_TOKEN} --min_speakers ${MIN_SPEAKERS} --max_speakers ${MAX_SPEAKERS} se DIARIZE=true] \
  --compute_type ${COMPUTE_TYPE:-int8} \
  --device cpu \
  --batch_size ${BATCH_SIZE:-4} \
  --output_dir /out
```

## Dicas de performance (CPU)

- Use modelos menores (`tiny/base/small`) para ganhar velocidade
- Se estiver sem o HF token ou quiser acelerar, desative diarização (veja abaixo)
- Ajuste `--batch_size` (no compose) para reduzir uso de RAM (ex.: `2` ou `1`)
- Feche apps pesados e aumente a memória do Docker Desktop (macOS) para evitar OOM/Killed

## Ativar/desativar diarização

- Para ativar: defina `DIARIZE=true` e preencha `HF_TOKEN` (Hugging Face).
- Para desativar: `DIARIZE=false` (padrão) ou deixe `HF_TOKEN` vazio.

## Solução de problemas

- Processo muito lento: escolha um modelo menor e/ou desative diarização
- Idioma: se `AUDIO_LANG` ficar vazio, o modelo tenta detectar automaticamente; se definir, use um código válido (ex.: `pt`, `en`, `es`)
- “Killed”/memória insuficiente: reduza `--batch_size`, escolha um modelo menor e/ou aumente memória do Docker Desktop
- HF token inválido: gere/cole um token em https://huggingface.co/settings/tokens e exporte em `HF_TOKEN`
- Cache muito grande: remova o volume de cache (atenção: baixa novamente os modelos)
  - Liste volumes: `docker volume ls`
  - Remova com: `docker volume rm <nome-do-volume-do-cache>`
  - Ou limpe tudo do projeto: `docker compose down -v` (remove containers e volumes do compose)

## Créditos

- WhisperX: https://github.com/m-bain/whisperx
- WhisperXMac: https://github.com/justinwlin/WhisperXMac
- Este projeto apenas empacota a execução em Docker para uso em CPU/macOS e máquinas sem GPU.
