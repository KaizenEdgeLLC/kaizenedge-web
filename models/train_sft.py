import json
from datasets import Dataset
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments, Trainer
from peft import LoraConfig, get_peft_model

# Load config
cfg = json.load(open('models/config/sft.json'))

# Load base model + tokenizer
model = AutoModelForCausalLM.from_pretrained(cfg['base_model'])
tok = AutoTokenizer.from_pretrained(cfg['base_model'])
tok.pad_token = tok.eos_token

# Load dataset from JSONL
def gen_data(path):
    for line in open(path, 'r'):
        if not line.strip():
            continue
        ex = json.loads(line)
        yield {
            "text": f"### Instruction:\n{ex['instruction']}\n"
                    f"### Input:\n{ex.get('input','')}\n"
                    f"### Output:\n{ex['output']}"
        }

train = Dataset.from_list(list(gen_data(cfg['train_file'])))

# PEFT (LoRA) config
peft_cfg = LoraConfig(
    r=cfg["lora_r"],
    lora_alpha=cfg["lora_alpha"],
    lora_dropout=cfg["lora_dropout"],
    task_type='CAUSAL_LM'
)
model = get_peft_model(model, peft_cfg)

# Training args
args = TrainingArguments(
    output_dir=cfg["out_dir"],
    remove_unused_columns=False,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=16,
    learning_rate=cfg["lr"],
    num_train_epochs=cfg["epochs"],
    logging_steps=10,
    save_strategy="epoch"
)

# Collator
def collate(batch):
    toks = tok([b['text'] for b in batch], return_tensors='pt',
               padding=True, truncation=True, max_length=cfg["seq_len"])
    toks['labels'] = toks['input_ids'].clone()
    return toks

# Trainer
trainer = Trainer(
    model=model,
    args=args,
    train_dataset=train,
    data_collator=collate
)

# Train
trainer.train()

# Save
trainer.save_model(cfg["out_dir"])
tok.save_pretrained(cfg["out_dir"])


