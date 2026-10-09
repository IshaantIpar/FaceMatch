import cv2
import numpy as np
from insightface.app import FaceAnalysis


# Prototype configuration
MATCH_THRESHOLD = 0.40
SCORE_REFERENCE = 0.80


print("Loading face model...")

face_app = FaceAnalysis(name="buffalo_l")
face_app.prepare(
    ctx_id=-1,          # CPU
    det_size=(640, 640)
)

print("Face model loaded successfully.")


def get_face_embedding(image_bytes: bytes):
    """
    Detect exactly one face and return its face embedding.
    """

    # Convert image bytes into a NumPy array
    image_array = np.frombuffer(image_bytes, np.uint8)

    # Decode image
    image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

    if image is None:
        raise ValueError("Invalid image file.")

    # Detect faces
    faces = face_app.get(image)

    # No face
    if len(faces) == 0:
        raise ValueError(
            "No face detected. Please provide an image containing one face."
        )

    # More than one face
    if len(faces) > 1:
        raise ValueError(
            "Multiple faces detected. Please provide an image containing only one person."
        )

    # Return the embedding of the single detected face
    return faces[0].embedding


def calculate_cosine_similarity(embedding_1, embedding_2):
    """
    Calculate cosine similarity between two face embeddings.
    """

    dot_product = np.dot(embedding_1, embedding_2)

    magnitude_1 = np.linalg.norm(embedding_1)
    magnitude_2 = np.linalg.norm(embedding_2)

    similarity = dot_product / (magnitude_1 * magnitude_2)

    return similarity


def calculate_score(similarity):
    """
    Convert raw cosine similarity into a prototype 0-100 score.

    This is a normalized similarity score, NOT a probability.
    """

    score = (similarity / SCORE_REFERENCE) * 100

    # Keep score between 0 and 100
    score = max(0, min(100, score))

    return round(score)


def compare_faces(selfie_bytes: bytes, reference_bytes: bytes):
    """
    Compare the selfie and reference image.

    Returns:
        similarity: raw cosine similarity
        score: normalized 0-100 score
        result: MATCH / NO_MATCH
    """

    # Generate embeddings
    selfie_embedding = get_face_embedding(selfie_bytes)
    reference_embedding = get_face_embedding(reference_bytes)

    # Compare embeddings
    similarity = calculate_cosine_similarity(
        selfie_embedding,
        reference_embedding
    )

    # Convert similarity to user-facing score
    score = calculate_score(similarity)

    # Determine match
    if similarity >= MATCH_THRESHOLD:
        result = "MATCH"
    else:
        result = "NO_MATCH"

    return {
        "success": True,
        "similarity": round(float(similarity), 4),
        "score": score,
        "result": result
    }