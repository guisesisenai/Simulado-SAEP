CREATE TABLE colaboradores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha TEXT NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL
);

CREATE TABLE projetos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    colaborador_id INT REFERENCES colaboradores(id),
    categoria_id INT REFERENCES categorias(id),
    projeto_id INT REFERENCES projetos(id),
    data_agendamento DATE NOT NULL,
    prazo_entrega DATE NOT NULL,
    data_criacao TIMESTAMP,
    status VARCHAR(30) DEFAULT 'Pendente',
    CHECK (prazo_entrega >= data_agendamento),
    CHECK (status IN ('Pendente', 'Em andamento', 'Concluída'))
);

CREATE TABLE historico_tarefas (
    id SERIAL PRIMARY KEY,
    tarefa_id INT REFERENCES tarefas(id),
    descricao TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO colaboradores (nome, email, senha, ativo) VALUES
('João', 'joao@email.com', '123', TRUE),
('Maria', 'maria@email.com', '123', TRUE),
('Pedro', 'pedro@email.com', '123', FALSE);

INSERT INTO categorias (nome) VALUES
('Desenvolvimento'),
('Documentação'),
('Reunião');

INSERT INTO projetos (nome) VALUES
('Sistema Financeiro'),
('Site'),
('Aplicativo');

CREATE OR REPLACE FUNCTION fn_validar_tarefa()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM colaboradores
        WHERE id = NEW.colaborador_id AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Colaborador inativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_tarefa
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_tarefa();

CREATE OR REPLACE FUNCTION fn_historico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_tarefas (tarefa_id, descricao)
    VALUES (NEW.id, 'Tarefa criada');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historico
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_historico();

INSERT INTO tarefas (titulo, colaborador_id, categoria_id, projeto_id, data_agendamento, prazo_entrega, status) VALUES
('Criar tela de login', 1, 1, 1, '2026-11-13', '2026-11-15', 'Em andamento'),
('Criar documentação', 2, 2, 1, '2026-11-16', '2026-11-20', 'Pendente'),
('Fazer reunião', 1, 3, 2, '2026-11-25', '2026-12-01', 'Pendente');

CREATE VIEW vw_painel_principal AS
SELECT c.nome AS colaborador, t.titulo, cat.nome AS categoria,
t.prazo_entrega, t.status
FROM tarefas t
JOIN colaboradores c ON t.colaborador_id = c.id
JOIN categorias cat ON t.categoria_id = cat.id;

CREATE VIEW vw_cronograma_prazos AS
SELECT t.titulo, t.status, t.prazo_entrega,
(t.prazo_entrega - CURRENT_DATE) AS dias_restantes,
c.nome AS responsavel
FROM tarefas t
JOIN colaboradores c ON t.colaborador_id = c.id
ORDER BY t.prazo_entrega ASC;

