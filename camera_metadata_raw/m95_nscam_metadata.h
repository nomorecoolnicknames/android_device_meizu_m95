/*
 * The part of MediaTek's NSCam::IMetadata used by m95_scaler_raw.cpp, declared
 * from the vendor libmtkcam_metadata.so vtables.
 *
 * In this blob entryFor() returns a reference, not an entry by value. Objects
 * are only reached through vendor pointers, so only the vtable slot order has
 * to match; unused slots are placeholders. Nothing is defined or called by
 * symbol: the shim is linked before libmtkcam_metadata is loaded, and an
 * unresolved symbol would keep the provider from starting.
 *
 * 32-bit only, like the camera provider.
 */

#pragma once

#include <stdint.h>

namespace NSCam {

// The vtables mirror the blob's slot for slot, destructors as plain slots 0/1.
// Soong builds with -Werror=non-virtual-dtor, hence the scoped suppression.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnon-virtual-dtor"

typedef uint8_t MUINT8;
typedef int32_t MINT32;
typedef uint32_t MUINT32;
typedef int64_t MINT64;
typedef float MFLOAT;
typedef unsigned int MUINT;
typedef int MBOOL;
typedef int MERROR;

// An empty tag type passed by value to select an overload; it carries nothing.
template <typename T>
struct Type2Type {
    typedef T type;
};

class IMetadata {
public:
    class IEntry {
    public:
        virtual void slot00_complete_object_destructor();
        virtual void slot01_deleting_destructor();
        virtual MUINT32 tag() const;                                  // 2
        virtual MINT32 type() const;                                  // 3
        virtual MBOOL isEmpty() const;                                // 4
        virtual MUINT count() const;                                  // 5
        virtual void slot06_capacity();
        virtual void slot07_setCapacity();
        virtual void slot08_clear();
        virtual void slot09_removeAt();
        virtual void push_back(MUINT8 const& item, Type2Type<MUINT8>);  // 10
        virtual void slot11_editItemAt_u8();
        virtual void slot12_itemAt_u8();
        virtual void push_back(MINT32 const& item, Type2Type<MINT32>);  // 13
        virtual void slot14_editItemAt_i32();
        virtual void slot15_itemAt_i32();
        virtual void push_back(MFLOAT const& item, Type2Type<MFLOAT>);  // 16
        virtual void slot17_editItemAt_float();
        virtual void slot18_itemAt_float();
        virtual void push_back(MINT64 const& item, Type2Type<MINT64>);  // 19
        // Slots 20..42 (i64 accessors, double, MRational, MPoint, MSize, MRect,
        // IMetadata, Memory) are never called from here and are left out.

    private:
        // The blob stores the vtable at +0 and the Implementor at +4.
        void* mImplementor;
    };

    virtual void slot00_complete_object_destructor();
    virtual void slot01_deleting_destructor();
    virtual MBOOL isEmpty() const;                                    // 2
    virtual MUINT count() const;                                      // 3
    virtual void slot04_clear();
    virtual void slot05_remove();
    virtual void slot06_sort();
    virtual MERROR update(MUINT32 tag, IEntry const& entry);          // 7
    virtual IEntry& editEntryFor(MUINT32 tag);                        // 8: aborts on a missing tag
    virtual IEntry const& entryFor(MUINT32 tag) const;                // 9: empty entry when missing
    // Slots 10..14 (editEntryAt, entryAt, flatten, unflatten, dump) unused.

private:
    void* mImplementor;
};

#pragma clang diagnostic pop

}  // namespace NSCam

// MediaTek's scaler tags mirror Android's (section 13, same offsets).
enum : NSCam::MUINT32 {
    MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS = 0x000d000a,
    MTK_SCALER_AVAILABLE_MIN_FRAME_DURATIONS = 0x000d000b,
    MTK_SCALER_AVAILABLE_STALL_DURATIONS = 0x000d000c,
};

enum : NSCam::MINT32 {
    MTK_SCALER_AVAILABLE_STREAM_CONFIGURATIONS_OUTPUT = 0,
};
