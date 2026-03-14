#!/usr/bin/env python3
"""
LLM Local Deploy - Python SDK Example

This example demonstrates how to use the OpenAI-compatible API
provided by Ollama to interact with locally running LLMs.

Requirements:
    pip install openai

Usage:
    python chat.py
"""

import os
import sys
from openai import OpenAI

# Configure the client to use local Ollama endpoint
client = OpenAI(
    base_url=os.getenv("OLLAMA_API_URL", "http://localhost:11434/v1"),
    api_key="ollama",  # Required but unused for Ollama
)


def list_models():
    """List available models."""
    print("\n📚 Available Models:")
    print("-" * 40)

    models = client.models.list()
    for model in models.data:
        print(f"  • {model.id}")

    print()


def chat_completion(model: str = "llama3.2:3b"):
    """Simple chat completion example."""
    print(f"\n💬 Chat Completion with {model}:")
    print("-" * 40)

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Explain what a local LLM is in 2 sentences."},
        ],
        temperature=0.7,
        max_tokens=100,
    )

    print(f"Assistant: {response.choices[0].message.content}")
    print(f"\nTokens used: {response.usage.total_tokens}")
    print()


def streaming_chat(model: str = "llama3.2:3b"):
    """Streaming chat completion example."""
    print(f"\n🌊 Streaming Chat with {model}:")
    print("-" * 40)

    stream = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "user", "content": "Count from 1 to 5, one number per line."},
        ],
        stream=True,
    )

    print("Assistant: ", end="", flush=True)
    for chunk in stream:
        if chunk.choices and chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)

    print("\n")


def completion(model: str = "llama3.2:3b"):
    """Simple text completion example."""
    print(f"\n📝 Text Completion with {model}:")
    print("-" * 40)

    response = client.completions.create(
        model=model,
        prompt="The capital of France is",
        max_tokens=20,
        temperature=0.3,
    )

    print(f"Completion: {response.choices[0].text}")
    print()


def embeddings(model: str = "nomic-embed-text"):
    """Generate embeddings for text."""
    print(f"\n🔢 Embeddings with {model}:")
    print("-" * 40)

    try:
        response = client.embeddings.create(
            model=model,
            input="Hello, world!",
        )

        embedding = response.data[0].embedding
        print(f"Embedding dimension: {len(embedding)}")
        print(f"First 5 values: {embedding[:5]}")
        print()
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure the embedding model is installed:")
        print("  ./models/download-models.sh pull nomic-embed-text")
        print()


def multi_turn_conversation(model: str = "llama3.2:3b"):
    """Multi-turn conversation with context."""
    print(f"\n🔄 Multi-turn Conversation with {model}:")
    print("-" * 40)

    messages = [
        {"role": "system", "content": "You are a helpful coding assistant."},
    ]

    questions = [
        "What is Python?",
        "What are its main features?",
        "Give me a simple code example.",
    ]

    for question in questions:
        print(f"\nUser: {question}")

        messages.append({"role": "user", "content": question})

        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.7,
        )

        answer = response.choices[0].message.content
        print(f"Assistant: {answer[:200]}...")

        messages.append({"role": "assistant", "content": answer})

    print()


def main():
    """Run all examples."""
    print("=" * 50)
    print("  LLM Local Deploy - Python SDK Examples")
    print("=" * 50)

    # Check connection
    try:
        client.models.list()
        print("✅ Connected to Ollama API")
    except Exception as e:
        print(f"❌ Cannot connect to Ollama API: {e}")
        print("Make sure Ollama is running: ./scripts/start.sh")
        return

    # Run examples
    list_models()
    chat_completion()
    streaming_chat()
    completion()
    # embeddings()  # Requires nomic-embed-text model
    # multi_turn_conversation()

    print("=" * 50)
    print("  Examples completed!")
    print("=" * 50)


if __name__ == "__main__":
    main()