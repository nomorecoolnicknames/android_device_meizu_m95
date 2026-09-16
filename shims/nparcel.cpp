// libm95shim_nparcel: "box" ABI adapter for the Nougat android::Parcel that
// the stock MTK libril (shipped renamed as /vendor/lib64/librilimp.so) keeps
// by value on the stack and heap.
//
// librilimp reserves 104 bytes per Parcel (the Nougat LP64 size); the A13
// Parcel is 120 bytes, so its constructor would write past that storage.
//
// librilimp's 19 imported android::Parcel methods are renamed to
// android::Pbrcel in its .dynstr (same length) and this library is added to
// its DT_NEEDED, so those calls resolve here. The first 8 bytes of the
// 104-byte box hold a pointer to a heap-allocated real android::Parcel, and
// every method is proxied to it.
//
// This is safe because librilimp reads Parcel state only through these
// out-of-line methods, no Parcel object crosses the librilimp boundary (the
// IMS entry points take raw buffers), and String16 is a single pointer on
// both N and A13.

#include <cstddef>
#include <cstdint>

#include <binder/Parcel.h>
#include <utils/Errors.h>
#include <utils/String16.h>

namespace android {

// The box the compiler operates on: exactly the pointer we stash in librilimp's
// storage. sizeof(Pbrcel) == 8, well within librilimp's 104-byte reservation;
// nothing but mReal is ever touched.
class Pbrcel {
public:
    Pbrcel();
    ~Pbrcel();

    status_t        appendFrom(const Pbrcel* parcel, size_t start, size_t len);
    status_t        writeInt32(int32_t val);
    status_t        writeInt64(int64_t val);
    status_t        writeString16(const char16_t* str, size_t len);
    status_t        writeString16(const String16& str);
    status_t        write(const void* data, size_t len);
    status_t        setData(const uint8_t* buffer, size_t len);

    const void*     readInplace(size_t len) const;
    size_t          dataPosition() const;
    String16        readString16() const;
    void            setDataPosition(size_t pos) const;
    const char16_t* readString16Inplace(size_t* outLen) const;
    const uint8_t*  data() const;
    status_t        read(void* outData, size_t len) const;
    size_t          dataSize() const;
    status_t        readInt32(int32_t* pArg) const;
    int32_t         readInt32() const;

private:
    Parcel* mReal;
};

// First word of librilimp's box <-> the heap Parcel it stands for.
static inline Parcel* real(const Pbrcel* self) {
    return *reinterpret_cast<Parcel* const*>(self);
}

Pbrcel::Pbrcel() {
    mReal = new Parcel();
}

Pbrcel::~Pbrcel() {
    delete real(this);
}

status_t Pbrcel::appendFrom(const Pbrcel* parcel, size_t start, size_t len) {
    return real(this)->appendFrom(real(parcel), start, len);
}

status_t Pbrcel::writeInt32(int32_t val) {
    return real(this)->writeInt32(val);
}

status_t Pbrcel::writeInt64(int64_t val) {
    return real(this)->writeInt64(val);
}

status_t Pbrcel::writeString16(const char16_t* str, size_t len) {
    return real(this)->writeString16(str, len);
}

status_t Pbrcel::writeString16(const String16& str) {
    return real(this)->writeString16(str);
}

status_t Pbrcel::write(const void* data, size_t len) {
    return real(this)->write(data, len);
}

status_t Pbrcel::setData(const uint8_t* buffer, size_t len) {
    return real(this)->setData(buffer, len);
}

const void* Pbrcel::readInplace(size_t len) const {
    return real(this)->readInplace(len);
}

size_t Pbrcel::dataPosition() const {
    return real(this)->dataPosition();
}

String16 Pbrcel::readString16() const {
    return real(this)->readString16();
}

void Pbrcel::setDataPosition(size_t pos) const {
    real(this)->setDataPosition(pos);
}

const char16_t* Pbrcel::readString16Inplace(size_t* outLen) const {
    return real(this)->readString16Inplace(outLen);
}

const uint8_t* Pbrcel::data() const {
    return real(this)->data();
}

status_t Pbrcel::read(void* outData, size_t len) const {
    return real(this)->read(outData, len);
}

size_t Pbrcel::dataSize() const {
    return real(this)->dataSize();
}

status_t Pbrcel::readInt32(int32_t* pArg) const {
    return real(this)->readInt32(pArg);
}

int32_t Pbrcel::readInt32() const {
    return real(this)->readInt32();
}

}  // namespace android
