import cv2
import numpy as np
from insightface.app import FaceAnalysis


print("Loading face model...")

app = FaceAnalysis(name="buffalo_l")

# CPU mode
app.prepare(
    ctx_id=-1,
    det_size=(640, 640)
)

print("Face model loaded successfully.\n")


# --------------------------------------------------
# Function to extract face embedding
# --------------------------------------------------

def get_face_embedding(image_path):

    print(f"Processing: {image_path}")

    image = cv2.imread(image_path)

    if image is None:
        print(f"ERROR: Could not load {image_path}")
        return None

    faces = app.get(image)

    print(f"Faces detected: {len(faces)}")

    if len(faces) == 0:
        print(f"ERROR: No face detected in {image_path}")
        return None

    if len(faces) > 1:
        print(f"ERROR: Multiple faces detected in {image_path}")
        return None

    face = faces[0]

    print("Exactly one face detected!")
    print("Embedding shape:", face.embedding.shape)
    print("Embedding data type:", face.embedding.dtype)

    return face.embedding


# --------------------------------------------------
# Generate embeddings for both images
# --------------------------------------------------

embedding_1 = get_face_embedding("B1.jpeg")

print()

embedding_2 = get_face_embedding("C1.jpg")


# Stop if either image failed validation
if embedding_1 is None or embedding_2 is None:
    print("\nFace comparison could not be performed.")
    exit()


# --------------------------------------------------
# Calculate cosine similarity
# --------------------------------------------------

dot_product = np.dot(embedding_1, embedding_2)

magnitude_1 = np.linalg.norm(embedding_1)
magnitude_2 = np.linalg.norm(embedding_2)

similarity = dot_product / (magnitude_1 * magnitude_2)


# --------------------------------------------------
# Convert similarity to 0-100 prototype score
# --------------------------------------------------

score = ((similarity + 1) / 2) * 100


# --------------------------------------------------
# Display result
# --------------------------------------------------

print("\n========================================")
print("          FACE MATCH RESULT")
print("========================================")

print(f"Cosine similarity : {similarity:.4f}")
print(f"Match score       : {score:.2f}/100")

print("========================================")